
from gi.repository.Gtk import TextIter

from imitation import config


class ImitationIter(TextIter):

    """ Imitation extension of TextIter
    
    Concepts:
        Offset imitation:
            Traversing lines while imitating a previous offset.
            Offset types vary, e.g. char|word|match
        Buffer: space required to the right of iter (used for selections)
    
    """
    
    
    #### Public
    
    def copy(self):
        """ Extend to apply the ImitationIter class to new copies """
        iter_copy = super(ImitationIter, self).copy()
        iter_copy.__class__ = ImitationIter
        return iter_copy
    
    def buffer_copy(self, buff):
        """ Get iter at the end of the buffer (no line detection) """
        if buff == 0:
            return None
        new = self.copy()
        new.set_offset(new.get_offset() + buff)
        return new
    
    def next_offset_copy(self, up, buff=0, alt=False):
        """ Get new iter on next line with same offset """
        new = self.copy()
        offset_type, offset_data = self._imitate_offset_data(buff, alt)
        def recurse():
            if not new._next_line(up):
                return None
            if new._imitate_offset(offset_type, offset_data):
                return new
            return recurse()
        return recurse()
    
    
    #### Alternatives to standard TextIter methods
    
    def _forward_to_line_end_alt(self):
        """ forward_to_line_end (without changing lines) """
        if not self.ends_line():
            self.forward_to_line_end()
    
    def _set_line_offset_alt(self, offset, buff=0):
        """ set_line_offset (without changing lines) """
        max_offset = self._max_line_offset()
        if offset + buff > max_offset:
            return False
        elif offset == max_offset:
            self._forward_to_line_end_alt()
        else:
            self.set_line_offset(offset)
        return True
    
    
    #### Custom methods
    
    def _max_line_offset(self):
        """ Get the iter's max line offset """
        test = self.copy()
        test._forward_to_line_end_alt()
        return test.get_line_offset()
    
    def _get_line_text(self):
        """ Get text for the iter's line """
        start = self.copy()
        start._set_line_offset_alt(0)
        end = self.copy()
        end._forward_to_line_end_alt()
        return unicode(self.get_buffer().get_text(start, end, True), 'utf_8')
    
    def _get_line_offset_text(self):
        """ Get text from line start up to iter """
        return self._get_line_text()[:self.get_line_offset()]
    
    def _get_line_buffer_text(self, buff):
        """ Get text from iter up to buffer """
        end = self.buffer_copy(buff)
        return unicode(self.get_buffer().get_text(self, end, True), 'utf_8')
    
    def _next_line(self, up):
        """ Move to start of next line, or return False """
        if up:
            if self.get_line() == 0:
                return False
            self.backward_line()
        else:
            if self.get_line() == self.get_buffer().get_line_count() - 1:
                return False
            self.forward_line()
        return True
    
    
    #### Offset imitation
    
    def _imitate_offset_data(self, buff, alt):
        """ Get offset data for other lines to imitate """
        if not alt:
            return ('char', (self.get_line_offset(), buff))
        elif buff == 0:
            return ('word', self._get_word_offset())
        else:
            needle = self._get_line_buffer_text(buff)
            match_num = 1 + self._get_line_offset_text().count(needle)
            return ('match', (needle, match_num))
    
    def _imitate_offset(self, type_, data):
        """ Imitate offset given the offset data """
        if type_ == 'char':
            return self._set_line_offset_alt(*data)
        elif type_ == 'word':
            return self._set_word_offset(data)
        elif type_ == 'match':
            return self._set_match_offset(*data)
        return False
    
    def _set_match_offset(self, needle, match_num):
        """ Set match offset based on number of matches """
        text = self._get_line_text()
        match = 1
        offset = text.find(needle)
        while offset != -1:
            if match == match_num:
                return self._set_line_offset_alt(offset)
            offset = text.find(needle, offset + len(needle))
            match += 1
        return False
    
    def _measure_words(self, preset=None):
        """ Count the words (and remaining chars) up to the iter's offset
        
        words = seperator or non-seperator groups
        If preset: reverse the function (or return None if not possible)
        
        """
        text = self._get_line_text()
        words = 0
        chars = 0
        # start case exceptions
        if preset is None and self.starts_line():
            return (0, 0)
        if preset == (0, 0):
            return 0
        # init prev_is_sep to same as first char
        if text != '':
            prev_is_sep = text[0] in config.WORD_SEPERATORS
        # text[offset-1] -- offset -- text[offset]
        for offset in range(1, len(text)+1):
            chars += 1
            # check if between words
            if offset == len(text) or \
                    prev_is_sep != (text[offset] in config.WORD_SEPERATORS):
                prev_is_sep = not prev_is_sep
                words += 1
                chars = 0
            # mode specific
            if preset is not None:
                if (words, chars) == preset or words > preset[0]:
                    return offset
            elif offset == self.get_line_offset():
                return (words, chars)
        # words < preset[0]
        return None
    
    def _get_word_offset(self):
        """ Get word (and remaining chars) offset """
        if self.ends_line():
            # end hugging
            return None
        # start case
        return self._measure_words()
    
    def _set_word_offset(self, preset):
        """ Set char offset given preset word offset """
        if preset is None:
            # end hugging
            self._forward_to_line_end_alt()
            return True
        offset = self._measure_words(preset)
        if offset is not None:
            return self._set_line_offset_alt(offset)
        return False


