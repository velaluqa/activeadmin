export default function updateHistory(path) {
  window.history.pushState(null, document.title, path);
}
