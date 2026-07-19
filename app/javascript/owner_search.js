window.setupOwnerSearch = function(inputId, hiddenId, dropdownId, btnId, productionId) {
  var input    = document.getElementById(inputId);
  var hidden   = document.getElementById(hiddenId);
  var dropdown = document.getElementById(dropdownId);
  var btn      = document.getElementById(btnId);
  var debounce;
  input.addEventListener('input', function() {
    clearTimeout(debounce);
    hidden.value = '';
    btn.disabled = true;
    btn.classList.add('opacity-50', 'cursor-not-allowed');
    btn.classList.remove('cursor-pointer');
    debounce = setTimeout(function() {
      var q = input.value.trim();
      if (!q) { dropdown.hidden = true; return; }
      fetch('/productions/' + productionId + '/members?q=' + encodeURIComponent(q))
        .then(function(r) { return r.json(); })
        .then(function(users) {
          dropdown.innerHTML = '';
          if (!users.length) { dropdown.hidden = true; return; }
          users.forEach(function(u) {
            var li = document.createElement('li');
            li.textContent = u.name + ' [' + u.email + ']';
            li.style.cssText = 'padding:8px 12px;cursor:pointer;font-size:1.125rem;list-style:none';
            li.addEventListener('mouseenter', function() { li.style.background = '#f3f4f6'; });
            li.addEventListener('mouseleave', function() { li.style.background = ''; });
            li.addEventListener('click', function() {
              hidden.value = u.id;
              input.value  = u.name;
              dropdown.hidden = true;
              btn.disabled = false;
              btn.classList.remove('opacity-50', 'cursor-not-allowed');
              btn.classList.add('cursor-pointer');
            });
            dropdown.appendChild(li);
          });
          dropdown.hidden = false;
        });
    }, 200);
  });
  document.addEventListener('click', function(e) {
    if (!input.contains(e.target) && !dropdown.contains(e.target))
      dropdown.hidden = true;
  });
};
