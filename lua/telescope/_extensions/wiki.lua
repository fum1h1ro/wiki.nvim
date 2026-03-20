return require("telescope").register_extension({
  exports = {
    backlinks = require("wiki.telescope").backlinks,
    links = require("wiki.telescope").links,
    pages = require("wiki.telescope").pages,
    grep = require("wiki.telescope").grep,
  },
})
