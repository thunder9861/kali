from gettext import gettext as _
import gi.repository.Gtk as gtk
import os
import re

import regexsearchdialog as rsd

# String for creating menu option
ui_str = """
<ui>
    <menubar name="MenuBar">
        <menu name="SearchMenu" action="Search">
            <placeholder name="SearchOps_3">
                <menuitem name="Regular expression..." action="RegexSearch"/>
            </placeholder>
        </menu>
    </menubar>
</ui>
"""

class RegexSearchInstance(object):

    ###
    # Object initialization
    def __init__(self, window):
        self._window = window
        self.create_menu_item()
        self.load_dialog()

        self.search_terms = set()
        self.replace_terms = set()

    def update_ui(self):
        """
        Changes gEdit UI to enable the search.
        
        Currently, does nothing.
        """
        pass

    def create_menu_item(self):
        """
        Create a menu item in the "Tools" menu.
        """
        action = gtk.Action("RegexSearch", 
                _("Regular expression..."), 
                _("Search using regular expressions"), None)
        action.connect("activate", self.on_open_regex_dialog)

        action_group = gtk.ActionGroup("RegexSearchActions")
        action_group.add_action_with_accel(action, "<control>r")
        
        manager = self._window.get_ui_manager()
        manager.insert_action_group(action_group, -1)
        manager.add_ui_from_string(ui_str)


    def load_dialog(self):
        """
        Loads the search/replace dialog:
           - Create dialog instance
           - Connect widget signals
           - Put needed widgets in object variables. 
        """
        self._search_dialog = rsd.SearchDialog()
        self._search_dialog.set_default_response(gtk.ResponseType.ACCEPT)
        self._search_dialog.hide()
        self._search_dialog.set_transient_for(self._window)
        self._search_dialog.set_destroy_with_parent(True)
        self._search_dialog.connect("delete-event", 
                lambda _1, _2: self._search_dialog.hide_on_delete())

        self._find_button = self._search_dialog.find_button
        self._find_button.connect("clicked", self.on_find_button_clicked)

        self._replace_button = self._search_dialog.replace_button
        self._replace_button.connect("clicked", self.on_replace_button_clicked)
        self._replace_all_button = self._search_dialog.replace_all_button
        self._replace_all_button.connect("clicked", self.on_replace_all_button_clicked)

        close_button = self._search_dialog.close_button
        close_button.connect("clicked", self.on_close_button_clicked)

        self._search_text_box = self._search_dialog.search_entry
        self._search_text_box.get_child().set_activates_default(True)
        self._search_text_box.connect("changed", self.on_search_text_changed)

        self._replace_text_box = self._search_dialog.replace_entry
        self._replace_text_box.get_child().set_activates_default(True)
        self._replace_text_box.connect("changed", self.on_replace_text_changed)

        self._wrap_around_check = self._search_dialog.wrap_around_checkbutton
        self._use_backreferences_check = self._search_dialog.backreferences_checkbutton
        self._case_sensitive_check = self._search_dialog.case_sensitive_checkbutton

        self._search_dialog.table.show_all()

    def on_find_button_clicked(self, find_button):
        """
        Callback for "Find" button when clicked.
        """
        self.search_document()

    def on_replace_button_clicked(self, replace_button):
        """
        Callback for "Replace" button when clicked.
        """
        self.search_document(button = 'replace')

    def on_replace_all_button_clicked(self, replace_button):
        """
        Callback for "Replace all" button when clicked.
        """
        document = self._window.get_active_document()
        current_iter = document.get_iter_at_mark(document.get_insert())
        current_line = current_iter.get_line()
        current_line_offset = current_iter.get_line_offset()
        current_offset = current_iter.get_offset()
        start_iter = document.get_start_iter()
        end_iter = document.get_end_iter()
        alltext = unicode(document.get_text(start_iter, end_iter, False), "utf-8")
        
        regex = self.create_regex()
        if regex==None: return
        # Registering current search term and replacement
        self.register_search_and_replace_terms()

        replace_string = self._replace_text_box.get_child().get_text()
        if not self._use_backreferences_check.get_active():
            # turn \ into \\ so that backreferences are not done.
            replace_string = replace_string.replace('\\','\\\\') 
        
        new_string, n_replacements = regex.subn(replace_string, alltext)
        
        selection_bound_mark = document.get_mark("selection_bound")
        document.place_cursor(start_iter)
        document.move_mark(selection_bound_mark, end_iter)
        document.delete_selection(False, False)
        document.insert_at_cursor(new_string)

        # Returning to the original point
        number_of_lines = document.get_line_count()

        return_line = current_line if current_line < number_of_lines \
                else number_of_lines
        return_line_iter = document.get_iter_at_line(return_line)
        if return_line < number_of_lines-1:
            next_line = return_line+1
            next_line_iter = document.get_iter_at_line(next_line)
            number_of_chars = next_line_iter.get_offset() - \
                    return_line_iter.get_offset() - 1
        else:
            number_of_chars = document.get_end_iter().get_offset() - \
                    return_line_iter.get_offset()
                    
        current_line_offset = current_line_offset \
                if current_line_offset < number_of_chars \
                else number_of_chars

        return_iter = document.get_iter_at_line_offset(
                current_line, current_line_offset)
        document.place_cursor(return_iter)
        self.show_alert_dialog(u"%d replacement(s)." % (n_replacements))

    def on_close_button_clicked(self, close_button):
        """
        Callback for "Find" button when clicked.
        """
        self._search_dialog.hide()

    def create_regex(self):
        """
        Creates a new re.regex object from the content of the search box.
        """
        try:
            sought_text = unicode(self.get_search_term(), "utf-8")
            # note multi-line flag, and dot does not match newline.
            if self._case_sensitive_check.get_active():
                regex = re.compile(sought_text, re.MULTILINE)
            else:
                regex = re.compile(sought_text, re.MULTILINE | re.IGNORECASE)
        except:
            self.show_alert_dialog(u"Invalid regular expression.")
            return None
        return regex

    def on_search_text_changed(self, search_text_entry):
        """
        Called when the text to be sought is changed. Validates if the search
        input is a valid regex.
        
        search_text_entry
            The gtk.TextEntry with the text to be searched.
        """
        search_text  = self.get_search_term()
        replace_text_entry = self._replace_text_box

        valid_regex = self.valid_regular_expression(search_text)
        self._find_button.set_sensitive(valid_regex)
        self._replace_button.set_sensitive(valid_regex)
        self._replace_all_button.set_sensitive(valid_regex)

        self.on_replace_text_changed(replace_text_entry)

    def on_replace_text_changed(self, replace_text_entry):
        """
        Called when the text to be replaced is changed.
        
        replace_text_entry
            The gtk.TextEntry with the text that will replace the sought one.
        """
        if not self.enable_replace:
            replace_text = self.get_replace_term()
            search_text  =  self.get_search_term()
            
            if len(search_text) > 0 and len(replace_text) > 0:
                self._replace_button.set_sensitive(True)
                self._replace_all_button.set_sensitive(True)
                self.enable_replace = True

    def on_open_regex_dialog (self, action = None):
        """
        Opens the Regex Search dialog.
        """
        self.enable_replace = False
        self._search_dialog.show()

    def search_document(self, start_iter = None, wrapped_around = False, button = 'search'):
        """
        Searchs the document, starting from the current position of the
        cursor.
        
        start_iter
            Cursor position.
        
        wrapped_around
            Indicates if the search has already wrapped around.
        
        button
            A string describing the clicked dialog button. Can be either 
            'search' or 'replace'.
        """
        document = self._window.get_active_document()

        if start_iter == None:
            start_iter = document.get_iter_at_mark(document.get_insert())

        end_iter = document.get_end_iter()

        regex = self.create_regex()
        if regex==None: return

        # Registering current search term and replacement
        self.register_search_and_replace_terms(button == "replace")
            
        text = unicode(document.get_text(start_iter, end_iter, False), "utf-8")
        result = regex.search(text)

        if result != None:
            # There is a match
            self.mark_found(document, regex)
            self.handle_search_result(result, document, start_iter, wrapped_around, button)
        else:
            # No match found
            if self.should_wrap_around(wrapped_around, start_iter):
                # Let's wrap around, searching the whole document
                self.search_document(document.get_start_iter(), True,button)
            else:
                # We've already wrapped around. There's no match in the whole document.
                self.show_alert_dialog(u"No match found for regular expression \"%s\"." 
                        % self.get_search_term())

    def handle_search_result(self, result, document, start_iter, wrapped_around = False,button='search'):
        """
        Handle search's result.
        
        If the result is already selected, we search for the next match.
        Otherwise we show it.
        
        The parameter "result" should contain the match result of a regex 
        search.
        
        result
            A match of a regex.
        
        document
            The document being searched.
        
        start_iter
            
        wrapped_around
            Indicates if the search has already wrapped around.
        
        button
            A string describing the clicked dialog button. Can be either 
            'search' or 'replace'.
        """
        curr_iter = document.get_iter_at_mark(document.get_insert())

        selection_bound_mark = document.get_mark("selection_bound")
        selection_bound_iter = document.get_iter_at_mark(selection_bound_mark)

        if button=='search':
            # If our result is already selected, we will search again starting from the end of
            # of the current result.
            if start_iter.get_offset() + result.start() == curr_iter.get_offset() and \
               start_iter.get_offset() + result.end() == selection_bound_iter.get_offset():

                start_iter.forward_chars(result.end()+1) # To the first char after the current selection/match.

                # fixed bug- no wrapping when match at end of document, used to be get_offset() < document
                if start_iter.get_offset() <= document.get_end_iter().get_offset() and not wrapped_around:
                    self.search_document(start_iter,False,button)
            else:
                self.show_search_result(result, document, start_iter, button)
        else:
            # If we are replacing, and there is a selection that matches, we want to replace the selection.
            # don't advance the cursor
            self.show_search_result(result, document, start_iter, button)


    def show_search_result(self, result, document, start_iter,button):
        """
        Show search's result.
        
        i.e.: Select the search result text, scroll to that position, etc.
    
        The parameter "result" should contain the match result of a regex search.
        """
        selection_bound_mark = document.get_mark("selection_bound")

        result_start_iter = document.get_iter_at_offset(start_iter.get_offset() + result.start())
        result_end_iter = document.get_iter_at_offset(start_iter.get_offset() + result.end())

        document.place_cursor(result_start_iter)
        document.move_mark(selection_bound_mark, result_end_iter)

        if (button == 'replace'):
            replace_text = self._replace_text_box.get_child().get_text()
            self.replace_text(document,replace_text, result)

        view = self._window.get_active_view()
        view.scroll_to_cursor()

    def replace_text(self,document,replace_string, result):
        """
        Replaces the text from a selection on the document.
        
        document
            The document containing the text to be replaced.
            
        replace_string
            The content to replace.
        
        result
            The regex match result.
        """
        try:
            if not self._use_backreferences_check.get_active():
                replace_text = replace_string
            else:
                replace_text = result.expand(replace_string) # perform backslash expansion, like \1
            document.delete_selection(False, False)
            document.insert_at_cursor(replace_text)
        except re.error:
            self.show_alert_dialog(_("Invalid group reference"))
    
    def valid_regular_expression(self, text):
        """
        Returns True if the text is a not empty valid regular expression.
        Returns False, otherwise.
        
        text
            The text which can be a regular expression.
        """
        if len(text) > 0:
            # Verifying if the regular expression is valid
            try:
                re.compile(unicode(text, "utf-8"))
            except re.error:
                return False
            else:
                return True
        else:
            return False

    def should_wrap_around(self, wrapped_around, start_iter):
        """
        Returns True if the search should wrap around (i.e., restart from the
        begining); returns False, otherwise.
        
        wrapped_around
            Indicates if the search was already wrapped around.
        """
         # Verifies if the wrap option selected, the wrapping was not made yet 
         # and the search start point is not document begining.
        return self._wrap_around_check.get_active() \
               and not wrapped_around \
               and start_iter.get_offset() > 0

    def mark_found(self, document, regex):
        """
        Marks all matches with a different background color, as it is made by
        the default gEdit search.
        
        document
            The document with matches.
        
        regex
            The regex to match.
        """
        text = document.get_text(document.get_start_iter(), document.get_end_iter(), True)
        document.remove_tag_by_name("found", document.get_start_iter(), document.get_end_iter())
        for match in regex.finditer(text):
            start = document.get_iter_at_offset(match.start())
            end = document.get_iter_at_offset(match.end())
            document.apply_tag_by_name("found", start, end)

    def show_alert_dialog(self, s):
        dlg = gtk.MessageDialog(self._window,
                                gtk.DialogFlags.DESTROY_WITH_PARENT,
                                gtk.MessageType.INFO,
                                gtk.ButtonsType.CLOSE,
                                _(s))
        dlg.run()
        dlg.hide()

    def get_search_term(self):
        return self._search_text_box.get_child().get_text()

    def get_replace_term(self):
        return self._replace_text_box.get_child().get_text()

    def register_search_and_replace_terms(self, register_replace=True):
        search_term = self.get_search_term()
        if search_term not in self.search_terms:
            self._search_text_box.prepend(None, search_term)
            self.search_terms.add(search_term)
        if register_replace:
            replace_term = self.get_replace_term()
            if replace_term not in self.replace_terms:
                self._replace_text_box.prepend(None, replace_term)
                self.replace_terms.add(replace_term)
