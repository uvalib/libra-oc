(function() {
    "use strict";

    function initPage() {

        // enable the date picker...
        $( '.exports .date-picker' ).datepicker({
            dateFormat: "yy-mm-dd"
        });

        // export handler
        $('.exports .exporter' ).on("click", function( ev ) {
            ev.preventDefault();
            var export_type = $( this ).attr( 'data' );
            var start_date = getDateOrBeginingOfTime( '#export-start-date' );
            var end_date = getDateOrToday( '#export-end-date' );
            var constraints = "type=" + export_type + "&start_date=" + start_date + "&end_date=" + end_date;
            getExports( constraints );
        });

    }

    function getExports( constraints ) {
        var url = "/exports/get.csv?" + constraints;
        console.log( "export URL: " + url );
        window.location = url;
    }

    function getDateOrToday( field_id ) {
        var date = $( field_id ).val( );
        if ( date.length === 0 ) {
            date = new Date( ).toISOString( ).slice( 0, 10 );
        }
        return date
    }

    function getDateOrBeginingOfTime( field_id ) {
        var date = $( field_id ).val( );
        if ( date.length === 0 ) {
            date = '2000-01-01';
        }
        return date
    }

    document.addEventListener("turbolinks:load", function() {
        initPage();
    });
})();