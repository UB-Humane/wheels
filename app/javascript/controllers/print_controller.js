import { Controller } from "@hotwired/stimulus"

const FONTS_URL = "https://fonts.googleapis.com/css2?" +
  "family=Inter:wght@400;700" +
  "&family=Noto+Sans:wght@400;700" +
  "&family=IBM+Plex+Sans:wght@400;700" +
  "&family=Public+Sans:wght@400;700" +
  "&family=Atkinson+Hyperlegible:wght@400;700" +
  "&display=swap"

// window.onload fires once the Google Fonts stylesheet reference has loaded, not once the
// actual webfont files have downloaded and swapped in — printing on load risked capturing the
// page still in its fallback font, reintroducing the very cross-browser metrics mismatch this
// was meant to fix. document.fonts.ready waits for the real font to actually be applied.
const PRINT_SCRIPT =
  '<script>' +
    'function go(){window.print();window.close();}' +
    'if (document.fonts && document.fonts.ready) { document.fonts.ready.then(go); } else { window.onload = go; }' +
  '<\/script>'

export default class extends Controller {
  static targets = [ "printedBadge" ]
  static values = {
    bikes: Array, requestor: String, source: String, codename: String, phone: String, owner: String, due: String,
    paddingTop: Number, paddingRight: Number, paddingBottom: Number, paddingLeft: Number, font: String,
    markPrintedUrl: String
  }

  printLabels() {
    const bikes = this.bikesValue, source = this.sourceValue, codename = this.codenameValue
    var pages = []
    bikes.forEach(function(b, i) {
      var name = b[0], type = b[1], age = b[2], height = b[3], notes = b[4]
      var rows = []
      rows.push('<div style="font-size:13pt;font-weight:bold;line-height:1.25;margin-bottom:2mm">' + source + '</div>')
      rows.push('<div style="font-size:12pt;line-height:1.25;margin:0.5mm 0">Name: ' + (name || '-') + '</div>')
      rows.push('<div style="font-size:12pt;line-height:1.25;margin:0.5mm 0">Sex: ' + (type || '-') + '</div>')
      rows.push('<div style="font-size:12pt;line-height:1.25;margin:0.5mm 0">Age: ' + (age || '-') + '</div>')
      rows.push('<div style="font-size:12pt;line-height:1.25;margin:0.5mm 0">Height: ' + (height || '-') + '</div>')
      rows.push('<div style="font-size:12pt;line-height:1.25;margin:0.5mm 0">Notes: ' + (notes || '-') + '</div>')
      var footer =
        '<div style="text-align:center">' +
          '<div style="font-size:20pt;font-weight:bold;line-height:1.1">' + codename + '</div>' +
          '<div style="font-size:15pt;line-height:1.25;margin-top:1mm">' + (i + 1) + '/' + bikes.length + '</div>' +
        '</div>'
      pages.push(
        '<div style="' + (pages.length > 0 ? 'page-break-before:always;' : '') +
          'width:50mm;height:80mm;box-sizing:border-box;padding:3mm 3mm 6mm;overflow:hidden;display:flex;flex-direction:column;justify-content:space-between">' +
          '<div>' + rows.join('') + '</div>' +
          footer +
        '</div>'
      )
    })
    var font = "'" + this.fontValue + "', sans-serif"
    var win = window.open('', '_blank', 'width=400,height=600')
    win.document.write('<html><head><link rel="stylesheet" href="' + FONTS_URL + '"><style>@page { size: 50mm 80mm; margin: 0; }</style></head><body style="font-family:' + font + ';margin:0">' + pages.join('') + PRINT_SCRIPT + '</body></html>')
    win.document.close()
    this._markPrinted()
  }

  _markPrinted() {
    const token = document.querySelector('meta[name="csrf-token"]').content
    fetch(this.markPrintedUrlValue, {
      method: "PATCH",
      headers: { "X-CSRF-Token": token }
    }).then(response => {
      if (!response.ok) return
      if (this.hasPrintedBadgeTarget) this.printedBadgeTarget.hidden = false
      if (!this.element.classList.contains("border-red-600")) {
        this.element.classList.remove("border-gray-900")
        this.element.classList.add("border-green-600")
      }
    })
  }

  printCard() {
    const bikes = this.bikesValue, requestor = this.requestorValue, source = this.sourceValue, codename = this.codenameValue, phone = this.phoneValue, owner = this.ownerValue, due = this.dueValue
    var cellStyle = 'padding:4px 8px;font-size:11pt;text-align:left;white-space:nowrap'
    var rows = ''
    bikes.forEach(function(b, i) {
      var name = b[0], type = b[1], age = b[2], height = b[3], notes = b[4]
      rows += '<tr style="border-bottom:1px solid #ddd">'
      rows += '<td style="' + cellStyle + ';color:#888">' + (i + 1) + '</td>'
      rows += '<td style="' + cellStyle + ';font-weight:bold">' + (name || '-') + '</td>'
      rows += '<td style="' + cellStyle + '">' + (type || '-') + '</td>'
      rows += '<td style="' + cellStyle + '">' + (age || '-') + '</td>'
      rows += '<td style="' + cellStyle + '">' + (height || '-') + '</td>'
      rows += '<td style="' + cellStyle + ';color:#666;white-space:normal">' + (notes || '-') + '</td>'
      rows += '</tr>'
    })
    var headerStyle = 'padding:4px 8px;font-size:10pt;text-align:left;color:#888;border-bottom:2px solid #000'
    var html =
      '<div style="border-bottom:2px solid #000;padding-bottom:10px;margin-bottom:14px">' +
        '<div style="font-size:20pt;font-weight:bold">' + source + '</div>' +
        '<div style="font-size:14pt;font-weight:bold;margin-top:2px">' + codename + '</div>' +
        '<div style="font-size:14pt;margin-top:2px">Requested By ' + requestor + ' (' + phone + ')</div>' +
        (owner ? '<div style="font-size:14pt;margin-top:2px">Owned By ' + owner + '</div>' : '') +
        '<div style="font-size:13pt;color:#555;margin-top:3px">Due ' + due + '</div>' +
      '</div>' +
      '<table style="width:100%;border-collapse:collapse">' +
        '<thead><tr>' +
          '<th style="' + headerStyle + '">#</th>' +
          '<th style="' + headerStyle + '">Name</th>' +
          '<th style="' + headerStyle + '">Type</th>' +
          '<th style="' + headerStyle + '">Age</th>' +
          '<th style="' + headerStyle + '">Height</th>' +
          '<th style="' + headerStyle + '">Notes</th>' +
        '</tr></thead>' +
        '<tbody>' + rows + '</tbody>' +
      '</table>' +
      '<div style="margin-top:28px">' +
        '<div style="font-size:11pt;color:#888;margin-bottom:12px">Notes</div>' +
        '<div style="border-bottom:1px solid #999;height:32px"></div>' +
        '<div style="border-bottom:1px solid #999;height:32px"></div>' +
        '<div style="border-bottom:1px solid #999;height:32px"></div>' +
      '</div>'
    var padding = this.paddingTopValue + 'px ' + this.paddingRightValue + 'px ' + this.paddingBottomValue + 'px ' + this.paddingLeftValue + 'px'
    var font = "'" + this.fontValue + "', sans-serif"
    var win = window.open('', '_blank', 'width=700,height=1000')
    win.document.write('<html><head><link rel="stylesheet" href="' + FONTS_URL + '"><style>@page { size: A5; margin: 8mm; }</style></head><body style="font-family:' + font + ';padding:' + padding + ';max-width:660px">' + html + PRINT_SCRIPT + '</body></html>')
    win.document.close()
  }
}
