// Pure page commands shared by runtime and selected settings editors.
function clone(value) { return JSON.parse(JSON.stringify(value)); }
function names(pages, pending) {
  var result = Object.create(null);
  for (var page of pages) {
    var key = String(page.id);
    result[key] = pending && Object.prototype.hasOwnProperty.call(pending, key) ? pending[key] : page.name;
  }
  return result;
}
function create(pages, name) {
  var next = clone(pages);
  var id = next.length > 0 ? Math.max(...next.map(page => page.id)) + 1 : 0;
  next.push({id: id, name: name});
  return next;
}
function rename(pages, id, name) {
  return pages.map(function(page) { return page.id === id ? Object.assign({}, page, {name: name}) : clone(page); });
}
function remove(pages, todos, current, id) {
  return {pages: pages.filter(page => page.id !== id).map(clone),
          todos: todos.map(function(todo) { return todo.pageId === id ? Object.assign({}, todo, {pageId: 0}) : clone(todo); }),
          current: current === id ? 0 : current};
}
