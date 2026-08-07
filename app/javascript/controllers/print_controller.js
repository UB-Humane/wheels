import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { bikes: Array, requestor: String, phone: String, due: String }

  printLabels() {
    const bikes = this.bikesValue, requestor = this.requestorValue, phone = this.phoneValue, due = this.dueValue
    var pages = []
    bikes.forEach(function(b, i) {
      var name = b[0], type = b[1], age = b[2], height = b[3], notes = b[4]
      var lines = []
      lines.push('<p style="font-size:11pt;color:#555;margin:0 0 4px">' + (i + 1) + '/' + bikes.length + '</p>')
      if (name) lines.push('<p style="font-size:18pt;font-weight:bold;margin:0">' + name + '</p>')
      var detail = type
      if (age) detail += ' &middot; Age ' + age
      if (height) detail += ' &middot; ' + height
      lines.push('<p style="font-size:14pt;margin:4px 0">' + detail + '</p>')
      if (notes) lines.push('<p style="font-size:12pt;margin:4px 0">' + notes + '</p>')
      lines.push('<p style="font-size:11pt;color:#555;margin:8px 0 0">' + requestor + ' &middot; ' + phone + '</p>')
      lines.push('<p style="font-size:11pt;color:#555;margin:2px 0">Due ' + due + '</p>')
      pages.push('<div style="' + (pages.length > 0 ? 'page-break-before:always;' : '') + 'padding:12px">' + lines.join('') + '</div>')
    })
    var win = window.open('', '_blank', 'width=400,height=600')
    win.document.write('<html><body style="font-family:sans-serif;margin:0">' + pages.join('') + '<script>window.onload=function(){window.print();window.close();}<\/script></body></html>')
    win.document.close()
  }

  printCard() {
    const bikes = this.bikesValue, requestor = this.requestorValue, phone = this.phoneValue, due = this.dueValue
    var rows = ''
    bikes.forEach(function(b, i) {
      var name = b[0], type = b[1], age = b[2], height = b[3], notes = b[4]
      var specs = [type, age ? 'Age ' + age : '', height].filter(Boolean).join(' · ')
      rows += '<tr style="border-bottom:1px solid #ddd">'
      rows += '<td style="padding:8px 10px;font-size:13pt;color:#888;vertical-align:top">' + (i + 1) + '</td>'
      rows += '<td style="padding:8px 10px;vertical-align:top">'
      if (name) rows += '<div style="font-size:15pt;font-weight:bold;margin-bottom:2px">' + name + '</div>'
      rows += '<div style="font-size:13pt;color:#333">' + specs + '</div>'
      if (notes) rows += '<div style="font-size:12pt;color:#666;margin-top:3px">' + notes + '</div>'
      rows += '</td></tr>'
    })
    var html =
      '<div style="border-bottom:2px solid #000;padding-bottom:10px;margin-bottom:14px">' +
        '<div style="font-size:18pt;font-weight:bold">' + requestor + '</div>' +
        '<div style="font-size:13pt;color:#555;margin-top:3px">' + phone + ' &nbsp;&middot;&nbsp; Due ' + due + '</div>' +
      '</div>' +
      '<table style="width:100%;border-collapse:collapse">' + rows + '</table>'
    var win = window.open('', '_blank', 'width=700,height=1000')
    win.document.write('<html><body style="font-family:sans-serif;padding:20px;max-width:660px">' + html + '<script>window.onload=function(){window.print();window.close();}<\/script></body></html>')
    win.document.close()
  }
}
