import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { bikes: Array, requestor: String, source: String, codename: String, phone: String, owner: String, due: String }

  printLabels() {
    const bikes = this.bikesValue, source = this.sourceValue, codename = this.codenameValue
    var pages = []
    bikes.forEach(function(b, i) {
      var name = b[0], type = b[1], age = b[2], height = b[3], notes = b[4]
      var rows = []
      rows.push('<div style="font-size:9pt;font-weight:bold;margin-bottom:2mm">' + source + '</div>')
      rows.push('<div style="font-size:8pt;margin:0.5mm 0">Name: ' + (name || '-') + '</div>')
      rows.push('<div style="font-size:8pt;margin:0.5mm 0">Sex: ' + (type || '-') + '</div>')
      rows.push('<div style="font-size:8pt;margin:0.5mm 0">Age: ' + (age || '-') + '</div>')
      rows.push('<div style="font-size:8pt;margin:0.5mm 0">Height: ' + (height || '-') + '</div>')
      rows.push('<div style="font-size:8pt;margin:0.5mm 0">Notes: ' + (notes || '-') + '</div>')
      var footer =
        '<div style="text-align:center">' +
          '<div style="font-size:20pt;font-weight:bold;line-height:1.1">' + codename + '</div>' +
          '<div style="font-size:11pt;margin-top:1mm">' + (i + 1) + '/' + bikes.length + '</div>' +
        '</div>'
      pages.push(
        '<div style="' + (pages.length > 0 ? 'page-break-before:always;' : '') +
          'width:50mm;height:80mm;box-sizing:border-box;padding:3mm 3mm 6mm;display:flex;flex-direction:column;justify-content:space-between">' +
          '<div>' + rows.join('') + '</div>' +
          footer +
        '</div>'
      )
    })
    var win = window.open('', '_blank', 'width=400,height=600')
    win.document.write('<html><head><style>@page { size: 50mm 80mm; margin: 0; }</style></head><body style="font-family:sans-serif;margin:0">' + pages.join('') + '<script>window.onload=function(){window.print();window.close();}<\/script></body></html>')
    win.document.close()
  }

  printCard() {
    const bikes = this.bikesValue, requestor = this.requestorValue, source = this.sourceValue, codename = this.codenameValue, phone = this.phoneValue, owner = this.ownerValue, due = this.dueValue
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
        '<div style="font-size:20pt;font-weight:bold">' + source + '</div>' +
        '<div style="font-size:14pt;font-weight:bold;margin-top:2px">' + codename + '</div>' +
        '<div style="font-size:14pt;margin-top:2px">Requested By ' + requestor + ' (' + phone + ')</div>' +
        (owner ? '<div style="font-size:14pt;margin-top:2px">Owned By ' + owner + '</div>' : '') +
        '<div style="font-size:13pt;color:#555;margin-top:3px">Due ' + due + '</div>' +
      '</div>' +
      '<table style="width:100%;border-collapse:collapse">' + rows + '</table>'
    var win = window.open('', '_blank', 'width=700,height=1000')
    win.document.write('<html><body style="font-family:sans-serif;padding:20px;max-width:660px">' + html + '<script>window.onload=function(){window.print();window.close();}<\/script></body></html>')
    win.document.close()
  }
}
