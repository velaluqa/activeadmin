JSONEditor.defaults.themes.custom = JSONEditor.AbstractTheme.extend({
  getFormInputLabel: function(text) {
    var el = this._super(text);
    return el;
  },
  getFormInputDescription: function(text) {
    var el = this._super(text);
    el.style.fontSize = '.8em';
    el.style.margin = 0;
    el.style.display = 'inline-block';
    el.style.fontStyle = 'italic';
    return el;
  },
  getIndentedPanel: function() {
    var el = document.createElement('div');
    el.style = el.style || {};
    return el;
  },
  getChildEditorHolder: function() {
    var el = this._super();
    return el;
  },
  getHeaderButtonHolder: function() {
    var el = this.getButtonHolder();
    el.className = 'header button-holder';
    return el;
  },
  getButtonHolder: function() {
    var el = document.createElement('div');
    el.style = {};
    el.className = 'footer button-holder';
    return el;
  },
  getTable: function() {
    var el = this._super();
    el.style.borderBottom = '1px solid #ccc';
    el.style.marginBottom = '5px';
    return el;
  },
  addInputError: function(input, text) {
    input.style.borderColor = 'red';

    if(!input.errmsg) {
      var group = this.closest(input,'.input-row');
      input.errmsg = document.createElement('div');
      input.errmsg.setAttribute('class','errmsg');
      input.errmsg.style = input.errmsg.style || {};
      input.errmsg.style.color = 'red';
      group.appendChild(input.errmsg);
    }
    else {
      input.errmsg.style.display = 'block';
    }

    input.errmsg.innerHTML = '';
    input.errmsg.appendChild(document.createTextNode(text));
  },
  getSwitcher: function(options) {
    var switcher = this.getSelectInput(options);
    switcher.style = {};
    switcher.className = "select";
    return switcher;
  },
  getFormControl: function(label, input, description) {
    var el = document.createElement('div');
    el.className = 'input-row';
    if(label) el.appendChild(label);
    if(input.type === 'checkbox') {
      label.insertBefore(input,label.firstChild);
    }
    else {
      el.appendChild(input);
    }

    if(description) el.appendChild(description);
    return el;
  },
  removeInputError: function(input) {
    input.style.borderColor = '';
    if(input.errmsg) input.errmsg.style.display = 'none';
  },
  getProgressBar: function() {
    var max = 100, start = 0;

    var progressBar = document.createElement('progress');
    progressBar.setAttribute('max', max);
    progressBar.setAttribute('value', start);
    return progressBar;
  },
  updateProgressBar: function(progressBar, progress) {
    if (!progressBar) return;
    progressBar.setAttribute('value', progress);
  },
  updateProgressBarUnknown: function(progressBar) {
    if (!progressBar) return;
    progressBar.removeAttribute('value');
  },
  getTab: function(span) {
    var el = document.createElement('li');
    el.appendChild(span);
    el.style = el.style || {};
    return el;
  },
  markTabActive: function(tab) {
    tab.className = 'tab active';
  },
  markTabInactive: function(tab) {
    tab.className = 'tab inactive';
  }
});
