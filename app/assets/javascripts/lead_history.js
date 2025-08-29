$(document).ready(function() {
  var classes = ['export','export1','export2', 'lead-hist-export', 'lead-sms-export'];
  $.each(classes, function(i, c) {
    $('.' + c).click(function(){
      exportTableToCSV.apply(this, [$('table.'+c), 'export.csv']);
    });
  });

});

function exportTableToCSV($table, filename) {
  var $rows = $table.find('tr:has(td)'),
    tmpColDelim = String.fromCharCode(11), // vertical tab character
    tmpRowDelim = String.fromCharCode(0), // null character

    // actual delimiter characters for CSV format
    colDelim = '","',
    rowDelim = '"\r\n"',
    // Grab text from table into CSV formatted string
    csv = '"' + $rows.map(function (i, row) {
        var $row = $(row),
            $cols = $row.find('td');

        return $cols.map(function (j, col) {
            var $col = $(col),
                text = $col.text();

            return text.replace(/"/g, '""'); // escape double quotes

        }).get().join(tmpColDelim);

    }).get().join(tmpRowDelim).split(tmpRowDelim).join(rowDelim)
      .split(tmpColDelim).join(colDelim) + '"',

    // Data URI
    csvData = 'data:application/csv;charset=utf-8,' + encodeURIComponent(csv);
  $(this)
    .attr({
    'download': filename,
      'href': csvData,
      'target': '_blank'
  });
}