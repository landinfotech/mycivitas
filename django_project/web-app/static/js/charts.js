function stringDivider(str, width, spaceReplacer) {
    if (str.length>width) {
        var p=width
        for (;p>0 && str[p]!=' ';p--) {
        }
        if (p>0) {
            var left = str.substring(0, p);
            var right = str.substring(p+1);
            return left + spaceReplacer + stringDivider(right, width, spaceReplacer);
        }
    }
    return str;
}

function createPDF(element, element_width, position_x, position_y, or, community, num_of_del){

    document.getElementById("loadingScreen").style.display = "block";

    $('body').addClass('stop-scrolling')

    document.querySelectorAll('.pdf-print').forEach(function(val){
        val.style.display = "block"
    })

    var opt = {
        margin:       [2, 0, 1, 0],
        filename:     community + '.pdf',
        image:        { type: 'jpeg', quality: 2 },
        html2canvas:  { scale: 2, windowWidth: 612, width:element_width, x: position_x, y: position_y},
        jsPDF:        { unit: 'pt', format: 'letter', orientation: or }
    };
    // html2pdf().set(opt).from(element).save();
    html2pdf().from(element).set(opt).toPdf().get('pdf').then(function (pdf) {
        var totalPages = pdf.internal.getNumberOfPages(); 
        for (var i = 1; i <= totalPages; i++) {
            pdf.setPage(i);
            pdf.setFontSize(10);
            pdf.setTextColor(150);
            //divided by 2 to go center
            pdf.addImage("/static/img/pdf/mycivitas.png", "PNG", 20, 10, 140, 50)

            var fontsize = 300;
            var x = 0;

            pdf.setFontSize(12);
            pdf.text("MyCivitas is an all-inclusive, easy to use platform that lets you record", 232, 25,{align: 'left'})
            pdf.text("and manage your assets in one powerful information system.", 280, 45,  {align: 'left'})
            pdf.text("support@mycivitas.ca", 480, 65,  {align: 'left'})

            pdf.setDrawColor(1, 106, 192) 
            pdf.setFillColor(1, 106, 192) 
            pdf.rect(0, 80, 1000, 50, 'FD')

            pdf.setFontSize(15);
            pdf.setTextColor(255,255,255);

            pdf.setFontSize(15);
            pdf.setTextColor(255,255,255);
            pdf.text("Community: " + community, 600, 110, null, null, "right")

            pdf.setDrawColor(0, 0, 0)
            pdf.line(10, 730, 600, 730)
            pdf.setTextColor(0,0,0);
            pdf.setFontSize(7);
            pdf.text("This report is intended for informational and planning purposes only. The information is not intended to be used for surveying, engineering, or other uses that rely on high levels of accuracy and precision. Each user of MyCivitas is responsible for determining its suitability for their purpose. The information within this report is created from a subset of data from the MyCivitas database. Several parties are responsible for updating, editing, and adding information to the MyCivitas database. MyCivitas makes no claims, no representation, and no warranties, expressed or implied, concerning the validity, the reliability or the accuracy of the data.", 120, 745,{maxWidth: 380},  {align: 'justify'})
            pdf.addImage("/static/img/pdf/kartoza.png", "PNG", 5, 740, 110, 35)
            pdf.addImage("/static/img/pdf/landinfo.png", "PNG", 490, 730, 110, 55)
        } 

        for(var i = 0; i < num_of_del; i++){
            pdf.deletePage(pdf.internal.getNumberOfPages())
        }

        $('body').removeClass('stop-scrolling')
        
        document.querySelectorAll('.pdf-print').forEach(function(val){
            val.style.display = "none"
        })
        document.getElementById("loadingScreen").style.display = "none";
    }).save();

    
}

