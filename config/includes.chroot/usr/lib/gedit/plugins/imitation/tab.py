
import string

from gi.repository import Gtk
from gi.repository import Gdk

from imitation import config
from imitation.iter import ImitationIter


class ImitationTab():

    """ Apply Imitation to a tab
    
    Concepts:
        Marks:
            Places where edits will be imitated. A mark is stored as a TextMark
            pair, with the second TextMark representing the mark selection
        Mark selection: imitation of text selection (deleted when edit happens)
        Imitation mode: when self._marks is non-empty
    
    """

    def __init__(self, tab):
        """ Enable imitation """
        self._tab = tab
        if self._tab is None:
            return
        # Tab-related
        self._view = self._tab.get_view()
        self._doc = self._tab.get_document()
        # Mark-related
        self._marks = []
        self._sticky_mode = False
        self._del_mem = None
        # Events
        self._view_handler_id = self._view.connect('event', self._on_event)
        self._doc_handler_ids = [
            self._doc.connect('mark-set', self._on_mark_set),
            self._doc.connect_after('insert-text', self._after_insert_text),
            self._doc.connect('delete-range', self._on_delete_range),
            self._doc.connect_after('delete-range', self._after_delete_range),
            self._doc.connect('undo', self._on_incompat_action),
            self._doc.connect('redo', self._on_incompat_action),
        ]
        self._block_doc_handlers()  # Doc handlers used only in imitation mode
        # Selections style
        self._tag = self._doc.create_tag(None,
            background=config.MARK_SELECTION_BG,
            foreground=config.MARK_SELECTION_FG,
        )
    
    def originalise(self):
        """ Disable imitation """
        if self._tab is not None:
            # Clear marks
            self._do_clear_marks()
            # Disconnect from signals
            self._view.disconnect(self._view_handler_id)
            for handler_id in self._doc_handler_ids:
                self._doc.disconnect(handler_id)
    
    
    #### Doc handler control
    
    class _BlockDocHandlers():
        """ Block signals to all doc handlers (in 'with' statement) """
        def __init__(self, tab):
            self._tab = tab
        def __enter__(self):
            self._tab._block_doc_handlers()
        def __exit__(self, *exception_args):
            self._tab._unblock_doc_handlers()
    
    def _block_doc_handlers(self):
        """ Block signals to all doc handlers """
        for handler_id in self._doc_handler_ids:
            self._doc.handler_block(handler_id)
    
    def _unblock_doc_handlers(self):
        """ Unblock signals to all doc handlers """
        for handler_id in self._doc_handler_ids:
            self._doc.handler_unblock(handler_id)
    
    
    #### View Handlers
    
    def _on_event(self, view, event):
        """ Handle key presses
        
        Takes priority over other third-party handlers than if connected to
        the key-press-event directly (issues encountered otherwise).
        
        """
        if event.type == Gdk.EventType.KEY_PRESS:
            return self._on_key_press(view, event)
        return False
    
    def _on_key_press(self, view, event):
        """ Delegate key presses to sub-handlers """
        sub_handlers = [
            (config.MARK_TOGGLE, self._do_mark_toggle, ()),
            (config.MARK_UP, self._do_mark_vert, (True, False)),
            (config.MARK_DOWN, self._do_mark_vert, (False, False)),
            (config.MARK_ALT_UP, self._do_mark_vert, (True, True)),
            (config.MARK_ALT_DOWN, self._do_mark_vert, (False, True)),
        ]
        # Only valid if in imitation mode
        if self._marks:
            sub_handlers += [
                (config.CLEAR_MARKS, self._do_clear_marks, ()),
                (config.BACKSPACE, self._do_delete, (-1,)),
                (config.DELETE, self._do_delete, (1,)),
                (config.INCR_NUM, self._do_increment, (0,)),
                (config.INCR_NUM1, self._do_increment, (1,)),
                (config.INCR_LOWER, self._do_increment, ('a',)),
                (config.INCR_UPPER, self._do_increment, ('A',)),
            ]
        # Find and call sub-handler
        keyval = Gdk.keyval_to_lower(event.keyval)  # Accels always lowercase
        state = Gtk.accelerator_get_default_mod_mask() & event.state
        for accelerator, handler, args in sub_handlers:
            if keyval == accelerator[0] and state == accelerator[1]:
                handler(*args)
                return True
        return False
    
    
    #### Doc handlers (in imitation mode)
    
    def _on_incompat_action(self, *args):
        """ Handle actions that are incompatible with imitation mode """
        self._do_clear_marks()
    
    def _on_mark_set(self, doc, loc, mark):
        """ Handle cursor (insert) movement """
        if mark == self._doc.get_insert():
            if not self._sticky_mode:
                self._do_clear_marks()
    
    def _after_insert_text(self, doc, start, text, length):
        """ Handle text insertion (blocked during imitation inserts) """
        insert_mark = self._doc.get_insert()
        # Only handle inserts at insert mark
        if not start.equal(self._get_iter(insert_mark)):
            self._do_clear_marks()
            return
        # Imitation insert
        self._imitation_insert(text)
        # Undo standard insert (after imitation for undo support)
        start.assign(self._get_iter(insert_mark))
        end = start.copy()
        end.set_offset(end.get_offset() - length)
        with self._BlockDocHandlers(self):
            self._doc.delete(start, end)
        # Revalidate start iter (should be at insert mark)
        start.assign(self._get_iter(insert_mark))
    
    def _on_delete_range(self, doc, start, end):
        """ Handle non-imitation deletions """
        insert = self._get_imitation_iter()
        bound = self._get_imitation_iter(True)
        insert.order(bound)
        if start.equal(insert) and end.equal(bound):
            # Delete likely result of insertion (prepare to undo)
            # Remember deleted text and mark positions
            self._del_mem = ['', [insert.get_marks()]]
            while not insert.equal(bound):
                self._del_mem[0] += insert.get_char()
                insert.forward_char()
                self._del_mem[1].append(insert.get_marks())
    
    def _after_delete_range(self, doc, start, end):
        """ Handle non-imitation deletions """
        if self._del_mem is None:
            # Incompatible deletion
            self._do_clear_marks()
            return
        # Undo deletion
        start_mark = self._doc.create_mark(None, start, True)   # left gravity
        with self._BlockDocHandlers(self):
            self._doc.insert(start, self._del_mem[0])  # needs handler blocked
            i = self._get_iter(start_mark)
            for mark_set in self._del_mem[1]:
                for mark in mark_set:
                    if not mark.get_deleted():
                        self._doc.move_mark(mark, i)  # needs handler blocked
                i.forward_char()
        self._del_mem = None
    
    
    #### Imitation-event handlers
    
    def _on_start_imitating(self):
        """ Mark count changed from 0 to 1 """
        self._unblock_doc_handlers()
    
    def _on_stop_imitating(self):
        """ Mark count changed from 1 to 0 """
        self._block_doc_handlers()
        self._sticky_mode = False
    
    
    #### Mark actions
    
    def _do_mark_toggle(self):
        """ Toggle mark at cursor (with sticky mode) """
        if not self._marks or self._sticky_mode:
            # Toggle mark if not coming straight from a non-sticky mark_vert
            self._toggle_mark()
        self._sticky_mode = True
    
    def _do_mark_vert(self, up, alt):
        """ Mark vertically based on offset """
        size = self._get_selection_size()   # Call first! (orders cursor marks)
        # Get iters around current line
        current = self._get_imitation_iter()
        prev = current.next_offset_copy(not up, size, alt)
        next = current.next_offset_copy(up, size, alt)
        # No where to go
        if next is None:
            self._add_mark(current, size)
            return
        # Undo marks (detect path already marked)
        if not self._has_mark(prev) and self._has_mark(next):
            self._remove_marks(current)
        # Add marks
        else:
            self._add_mark(current, size)
            self._add_mark(next, size)
        # Move cursor
        with self._BlockDocHandlers(self):
            if size == 0:
                self._doc.place_cursor(next)
            else:
                self._doc.select_range(next, next.buffer_copy(size))
        self._view.scroll_mark_onscreen(self._doc.get_insert())
    
    def _do_clear_marks(self):
        """ Clear all marks (exit imitation mode) """
        for i in range(len(self._marks)):
            self._remove_mark_by_index(0)
    
    
    #### Internal mark actions
    
    def _add_mark(self, iter_, size):
        """ Add mark if not present """
        if not self._has_mark(iter_):
            start = self._doc.create_mark(None, iter_, False)
            start.set_visible(True)
            end = iter_.buffer_copy(size)
            if end is not None:
                self._doc.apply_tag(self._tag, iter_, end)
                end = self._doc.create_mark(None, end, False)
            self._marks.append((start, end))
            # Test if entered imitation mode
            if len(self._marks) == 1:
                self._on_start_imitating()
            return True
        return False
    
    def _toggle_mark(self):
        """ Toggle mark at cursor """
        size = self._get_selection_size()   # Call first! (orders cursor marks)
        start = self._get_imitation_iter()
        if not self._add_mark(start, size):
            self._remove_marks(start)
    
    def _has_mark(self, iter_):
        """ Detect if location has been marked already """
        if iter_ is not None:
            for mark in iter_.get_marks():
                if mark in (pair[0] for pair in self._marks):
                    return True
        return False
    
    def _remove_marks(self, iter_):
        """ Remove all marks at location (if present) """
        for mark in iter_.get_marks():
            for i in range(len(self._marks)):
                if mark == self._marks[i][0]:
                    self._remove_mark_by_index(i)
                    break
    
    def _remove_mark_by_index(self, i):
        """ Remove mark by self._marks index """
        start, end = self._marks[i]
        # remove end first since start needed for tag removal
        if end is not None:
            self._doc.remove_tag(
                self._tag,
                self._get_iter(start),
                self._get_iter(end)
            )
            self._doc.delete_mark(end)
        start.set_visible(False)    # Force redraw at mark loc
        self._doc.delete_mark(start)
        del self._marks[i]
        # Test if left imitation mode
        if not self._marks:
            self._on_stop_imitating()
    
    def _validate_marks(self):
        """ Remove any duplicate marks
        
        Marks should remain valid (no duplicates) if:
            No duplicates added by _add_mark
            This method called after text deletion
        
        """
        offsets = []
        for i in range(len(self._marks)-1, -1, -1):
            offset = self._get_iter(self._marks[i][0]).get_offset()
            if offset in offsets:
                self._remove_mark_by_index(i)
            else:
                offsets.append(offset)
    
    def _delete_mark_selections(self):
        """ Delete text in mark selections (clearing selections) """
        deleted = False
        for i, (start, end) in enumerate(self._marks):
            if end is not None:
                self._doc.delete(
                    self._get_iter(start),
                    self._get_iter(end),
                )
                self._doc.delete_mark(end)
                self._marks[i] = (start, None)
                deleted = True
        self._validate_marks()
        return deleted
    
    
    #### Edit actions
    
    def _user_action(f):
        """ Decorator for wrapping actions with user_action calls """
        def wrapper(self, *args):
            self._doc.begin_user_action()
            f(self, *args)
            self._doc.end_user_action()
        return wrapper
    
    # def _do_insert does not exist (special case)
    # triggered by any text-insertion rather than defined user actions
    # Handled by _after_insert_text
    
    @_user_action
    def _do_increment(self, val_start):
        """ Insert incremented values at marks """
        # Get list of values
        if val_start == 0:
            values = range(len(self._marks))
        if val_start == 1:
            values = range(1, 1 + len(self._marks))
        if val_start == 'a':
            values = string.ascii_lowercase
        if val_start == 'A':
            values = string.ascii_uppercase
        # Insert values
        with self._BlockDocHandlers(self):
            self._delete_mark_selections()
            for i, (start, end) in enumerate(self._marks):
                self._doc.insert(
                    self._get_iter(start),
                    str(values[i % len(values)])
                )
    
    @_user_action
    def _do_delete(self, amount):
        """ Delete text at marks """
        with self._BlockDocHandlers(self):
            # Delete mark selections before any adjacent text
            if not self._delete_mark_selections():
                for start, null in self._marks:
                    start = self._get_iter(start)
                    # Check delete is possible
                    if amount < 0 and start.is_start(): continue
                    if amount > 0 and start.is_end(): continue
                    end = start.copy()
                    end.set_offset(end.get_offset() + amount)
                    self._doc.delete(start, end)
                    self._validate_marks()
    
    
    #### Internal edit actions
    
    def _imitation_insert(self, text):
        """ Insert text at marks (wrapped by _after_insert_text handler) """
        with self._BlockDocHandlers(self):
            self._delete_mark_selections()
            for start, end in self._marks:
                self._doc.insert(self._get_iter(start), text)
    
    
    #### Iter related
    
    def _get_iter(self, mark):
        """ Get TextIter at mark """
        return self._doc.get_iter_at_mark(mark)
    
    def _get_imitation_iter(self, bound=False):
        """ Get an ImitationIter at cursor
        
        ImitationIter-s are only needed for offset calculation,
        otherwise TextIter-s will suffice.
        
        """
        if not bound:
            mark = self._doc.get_insert()
        else:
            mark = self._doc.get_selection_bound()
        iter_ = self._get_iter(mark)
        iter_.__class__ = ImitationIter
        return iter_
    
    def _get_selection_size(self):
        """ Get the selection size (deselect if across lines) """
        start = self._get_imitation_iter()
        end = self._get_imitation_iter(True)
        # Ensure insert is start (< bound)
        if start.compare(end) == 1:
            start, end = end, start
            with self._BlockDocHandlers(self):
                self._doc.select_range(start, end)
        # no selection
        if start.equal(end):
            return 0
        # valid selection
        elif start.get_line() == end.get_line():
            return end.get_line_offset() - start.get_line_offset()
        # invalid (multi-line) selection; clear selection
        else:
            self._doc.move_mark_by_name('selection_bound', start)
            return 0


