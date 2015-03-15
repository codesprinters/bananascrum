/**
 * Construct a jQuery.fn.tableSort() function.
 * @class jQuery.fn.tableSort() is a very fast and unobtrusive table sorter
 * striving to minimize the invasion in the original design.
 * Sorts alternately ascending and descending.
 * Sorts EVERY tbody, binds calling events to cells in definable row of thead.
 * No markup changes, no bound events lost, only CSS classes changed
 * No support for colspan and rowspan (yet)
 *
 * Usage:
 *
 * jQuery( 'table' ).tableSort( {
 *    headRow: 0,
 *    columns: {
 *        0: { type: 'html' },
 *        1: { type: 'string', sorted: 'asc' },
 *        2: { type: 'html' },
 *        3: { type: 'string' },
 *        4: { type: 'string' },
 *        8: { type: 'string' }
 *    },
 *    stripe: true,
 *    classes: {
 *        sorting: 'sorting',
 *        sortable: 'sortable',
 *        asc: 'asc',
 *        desc: 'desc',
 *        stripe: 'even'
 * } );
 *
 *
 *Copyright (c) 2009 Benjamin Erhart, http://www.tladesignz.com/
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 *
 * @version 0.4.1
 * @author berhart@tladesignz.com
 *
 * @requires jQuery jQuery 1.2.2
 * @extends jQuery
 * @addon
 * @constructor
 */
(function() {
    /**
     * @param {Object} an object to customize the behavior with following keys:
     *      headRow: {Number}       // row in thead to connect sorting handlers to
     *      stripe: {Boolean}       // if true, enables zebra striping of table
     *      columnType: 'html'      // default column type to set if 'columns' key is omitted
     *      decimalSymbol: '.'      // default decimal symbol to use in 'number' type columns
     *      dateParser: null        // Allows for own method to parse a date. Has to return an epoch
     *                              // (milliseconds since 1970-01-01 00:00:00 UTC)
     *                              // Example for use with Datejs ( http://www.datejs.com/ )
     *                              //          function( date ) { return Date.parse( date ).getTime(); }
     *
     *      columns: {              // setup of columns, omit to enable sort of all columns
     *
     *          {Number}: { type: {String}, sorted: {String} }
     *          .
     *          .                   // Key: No of column starting with 0
     *          .
     *          .                   // type: 'html', 'string', 'number', 'date'
     *                              // string: omits all tags, trims string (removes all leading and trailing whitespaces)
     *                              //           and uppercases letters before sorting
     *                              // number: tries to extract number and sorts numerical
     *                              // date: tries to remove all tags and trailing and leading whitespace and
     *                              //       puts the result through date.parse() if no own date parser function
     *                              //       is given, sorts numerical by epoch
     *                              // html: no preprocessing of cell content is done before sorting
     *
     *                              // sorted: 'asc' or 'desc'
     *                              // defines if the data is already sorted at init
     *                              // adds respective classes to column head
     *      }
     *      classes: {              // class names which will be set on...
     *          sorting: {String}   // ...table while sorting is in progress
     *          sortable: {String}  // ...head cells, to show this column is sortable
     *          asc: {String}       // ...head cell, to show that this column is sorted ascending
     *          desc: {String}      // ...head cell, to show that this column is sorted descending
     *          stripe: {String}    // ...all body rows no/2 = even (starting with 0!)
     *      }
     * @returns jQuery Object
     * @type Object
     */
    jQuery.fn.tableSort = function( options ) {
        var cols;

        var opt = jQuery.extend( {}, jQuery.fn.tableSort.defaults, options );

        opt.columnType = opt.columnType.toLowerCase();

        // check if opt.columns isn't empty
        // lowercase type and sorted if used
        for (cols in opt.columns) {
            if (opt.columns[ cols ].type) {
                opt.columns[ cols ].type = opt.columns[ cols ].type.toLowerCase();
            }

            if (opt.columns[ cols ].sorted) {
                opt.columns[ cols ].sorted = opt.columns[ cols ].sorted.toLowerCase();
            }
        }

        return this.each( function() {
            // Don't execute if no <thead>, because there's no place to bind sorting events
            if (this.tagName != 'TABLE' || !this.tHead) {
                if (typeof console == 'object') {
                    console.log( 'tableSort: Selected element is no <table> or has no <thead>.' );
                }
                return;
            }

            var cells = this.tHead.rows[ opt.headRow ].cells;
            var i = cells.length - 1;
            var j;
            var rows;

            if (typeof cols == 'undefined') {
                do {
                    opt.columns[i] = { type: opt.columnType };
                } while (i--);
                cols == true; // so next iteration this isn't called -> first table defines all others sortable columns
                i = cells.length - 1;
            }

            // bind options to table
            this.tsOpt = opt;

            stripe( this );

            do {
                if (opt.columns[ i ]) {
                    $( cells[ i ] )
                        .bind( 'click.tableSort', sort )
                        .addClass(
                            opt.classes.sortable
                            + (opt.columns[ i ].sorted ? (' ' + opt.classes[ opt.columns[ i ].sorted ]) : '')
                        )
                    ;
                }
            } while (i--);

            i = this.tBodies.length - 1;
            do {
                rows = this.tBodies[ i ].rows;
                j = rows.length - 1;

                // BUGFIX: Don't try to sort if <tbody> is empty
                if (j > -1) {
                    do {
                        rows[ j ].numbering = j;
                    } while (j--);
                }
            } while (i--);

        } );
    };

    /**
     * tableSort default settings, can be changed from outside
     */
    jQuery.fn.tableSort.defaults = {
        headRow: 0,
        columns: {},
        columnType: 'html',
        decimalSymbol: '.',
        dateParser: null,
        stripe: false,
        classes: {
            sorting: 'sorting',
            sortable: 'sortable',
            asc: 'asc',
            desc: 'desc',
            stripe: 'even'
        }
    };

    /**
     * Actual sorting function. Sorts column (defined through cellIndex of calling cell)
     * in every tbody in the table.
     * Fetches content of cells, prepares them according to defined content type,
     * pre-sorts them, and caches sorting result in tbody[i].tsData;
     * This is done once per column (only when used, naturally).
     * Actually sorts rows by moving them out of the DOM, reference them in an array,
     * sort that array according to pre-sorting and move the rows back into original tbody.
     * Therefore all bound events will be kept.
     *
     * @param {Object} Event Object from onclick event.
     * @private
     */
    function sort( evt ) {
        var t = evt.target;
        var table = t.offsetParent;
        var col = t.cellIndex;
        var opt = table.tsOpt;
        var colOpt = opt.columns[ col ];
        var desc = sortDirection( t, opt );

        $( table ).addClass( opt.classes.sorting );

        $( table.tBodies ).each( function() {
            var $rows = $( this.rows );
            var length = $rows.length;
            var data;
            var tmpData = [];
            var tmpTbody = document.createElement( 'tbody' );
            var tmpRows = [];
            var afterCare;
            var i;
            var decimalSymbolRe;


            // BUGFIX: Don't try to sort if <tbody> is empty
            if (length < 1) {
                return;
            }

            if (!this.tsData) {
                this.tsData = [];
            }
            data = this.tsData;

            // If column wasn't sorted before, extract data in cells, sort it and transpose data matrix
            // for fast access later on.
            if (!data[ col ]) {
                if (colOpt.type == 'number') {
                    if (opt.decimalSymbol == '.') {
                        afterCare = function( data ) {
                            return parseFloat( data.replace( /(<.*?>|\s)/g, '' ) );
                        };
                    }
                    else {
                        decimalSymbolRe = new RegExp( opt.decimalSymbol );

                        afterCare = function( data ) {
                            return parseFloat( data.replace( /(<.*?>|\s)/g, '' ).replace( decimalSymbolRe, '.' ) );
                        };
                    }
                }
                else if (colOpt.type == 'string') {
                    afterCare = function( data ) {
                        // For an unknown reason, JavaScript uses predefined RegExes in single line mode
                        // How to avoid that?
                        return data.replace( /<.*?>/g, '' ).replace( /^(\s*)(.*?)(\s*)$/, "$2" ).toUpperCase();
                    };
                }
                else if (colOpt.type == 'date') {
                    if (typeof opt.dateParser == 'function') {
                        afterCare = function( data ) {
                            var result = 0;
                            data = data.replace( /<.*?>/g, '' ).replace( /^(\s*)(.*?)(\s*)$/, "$2" );
                            try {
                                result = opt.dateParser( data );
                            }
                            catch( e ) {
                                if (typeof console == 'object') {
                                    console.log( 'tableSort: Custom dateParser throws error "' + e + '", argument "' + data + '"' );
                                }
                            }
                            return result;
                        };
                    } else {
                        afterCare = function( data ) {
                            // removes all tags and trims string
                            return Date.parse(
                                data.replace( /<.*?>/g, '' ).replace( /^(\s*)(.*?)(\s*)$/, "$2" )
                            );
                        };
                    }

                }
                else {
                    afterCare = function( data ) {
                        return data;
                    };
                }

                i = length - 1;
                do {
                    tmpData[ i ] = [ afterCare( $rows[ i ].cells[ col ].innerHTML ), $rows[ i ].numbering ];
                } while (i--);

                if (colOpt.type == 'number' || colOpt.type == 'date') {
                    tmpData.sort( sortNumHelper );
                }
                else {
                    tmpData.sort();
                }

                data = data[ col ] = [];
                i = length - 1;
                do {
                    data[ tmpData[ i ][1] ] = i;
                } while (i--);
            }
            else {
                data = data[ col ];
            }

            if (desc) {
                sortFunc = function( a, b ) {
                    return data[ a.numbering ] - data[ b.numbering ];
                };
            }
            else {
                sortFunc = function( a, b ) {
                    return data[ b.numbering ] - data[ a.numbering ];
                };
            }

            // create sortable array, move out of DOM, so sorting won't be visualized (Opera likes to do this...)
            i = length - 1;
            do {
                tmpRows.push( $rows[i] );
                tmpTbody.appendChild( $rows[i] );
            } while (i--);

            tmpRows.sort( sortFunc );

            // move back to DOM
            i = length - 1;
            do {
                this.appendChild( tmpRows[i] );
            } while (i--);

        } );
        stripe( table );
        $( table ).removeClass( opt.classes.sorting );
    };

    /**
     * Sort numbers in array, handle not-a-number errors.
     *
     * @private
     * @oaram {Number} first value to compare
     * @param {Number] second value to compare
     * @returns -1, 0, 1 meaning first value is lower, equal or higher than second
     * @type Number
     */
    function sortNumHelper( a, b ) {
        return isNaN( a[0] ) ? (isNaN( b[0] ) ? 0 : -1) : (isNaN( b[0] ) ? 1 : (a[0] - b[0]) );
    };

    /**
     * Stripes all rows of a table contained in tBodies.
     *
     * @private
     * @param {Object} DOM node of table which tbody rows shall get striped
     */
    function stripe( node ) {
        if (node.tsOpt.stripe) {
            var $tBodies = $( node ).children( 'tbody' );
            $tBodies.children( 'tr:even' ).addClass( node.tsOpt.classes.stripe );
            $tBodies.children( 'tr:odd' ).removeClass( node.tsOpt.classes.stripe );
        }
    };

    /**
     * Adds class showing sort direction to clicked tHead cell.
     * If cell already has class 'asc', switches to 'desc' and returns true, in order to
     * instruct calling sort function to sort descending.
     * Removes sort direction class from all siblings of this cell.
     *
     * @private
     * @param {Object} DOM node of tHead cell calling the sort function
     * @returns true if column should be sorted descending
     * @type Boolean
     */
    function sortDirection( node, opt ) {
        var $node = $( node );

        $node.siblings( '.' + opt.classes.sortable ).removeClass( opt.classes.asc + ' ' + opt.classes.desc );
        if ($node.hasClass( opt.classes.asc )) {
            $node.removeClass( opt.classes.asc ).addClass( opt.classes.desc );
            return true;
        }

        $node.removeClass( opt.classes.desc ).addClass( opt.classes.asc );
    };

})();

