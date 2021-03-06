var letters = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
               'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z']; // eslint-disable-line indent
var numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'shift+0', 'shift+1', 'shift+2', 'shift+3', 'shift+4', 'shift+5', 'shift+6', 'shift+7', 'shift+8', 'shift+9'];

function inputFocused() {
  return document.activeElement.tagName === 'INPUT';
}

// Use this helper except for escape binding.
// Otherwise typing in an input focuses elsewhere.
function bind(shortcut, handler, return_true) {
  Mousetrap.bind(shortcut, function() {
    if (inputFocused()) return ;
    handler();
    return return_true ? true : false;
  }, 'keydown');
}

$(document).ready(function() {
  bind(letters, function() {
    $('#trigramme-search').focus();
  }, true);
  bind(numbers.concat(['.']), function() {
    $('#log-form #amount').focus();
  }, true);
  bind('ctrl+f', function() {
    $('#account-search').focus();
  }, true);
  bind('+', function() {
    $('#credit-form #amount').focus();
  });
  bind('ctrl+w', function() {
    $('#clopes-form #_clope_id').focus();
  });
  bind('ctrl+t', function() {
    $('#transfer-form #amount').focus();
  });
  bind('ctrl+alt+m', function() {
    $('#send-debt-mail').click();
  });
  Mousetrap.bind('esc', function () {
    if (document.activeElement.tagName === 'BODY') {
      window.location.href = '/';
    } else {
      document.activeElement.blur();
    }
  });
});
