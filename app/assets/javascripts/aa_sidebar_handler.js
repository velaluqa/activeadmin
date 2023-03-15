$(document).ready(function() {
    $('#sidebar').on('click', function(e) {
        e.stopPropagation();
    });

    $('a[data-toggle-sidebar-sections]').click(function() {
        var sections = $(this).data("toggle-sidebar-sections").split(",")
        var selector = sections.map(function(section) {
            return `#${section}_sidebar_section`;
        }).join(",");
        $('.sidebar_section.panel').not(selector).hide();
        $(selector).toggle();
        handleOverlay()
        setButtontext(selector);
    });

    $('body').on('click', '#sidebar_overlay', function() {
        $('.sidebar_section.panel').hide();
        handleOverlay();
        setButtontext();
    });

    function handleOverlay() {
        if ($('.sidebar_section.panel:visible').length > 0) {
            if ($('#sidebar_overlay').length == 0) {
                $('body').append('<div id="sidebar_overlay"></div>');
            }
        } else {
            $('#sidebar_overlay').remove();
        }
    }

    function setButtontext(selector) {
        if ($('.sidebar_section.panel:visible').length > 0) {
            $('a[data-toggle-sidebar-sections]').each(function() {
                var buttonSections = $(this).data("toggle-sidebar-sections").split(",")
                var buttonSelector = buttonSections.map(function(section) {
                    return `#${section}_sidebar_section`;
                }).join(",");
                if (buttonSelector == selector) {
                    $(this).text($(this).text().replace("View", "Hide"));
                } else {
                    $(this).text($(this).text().replace("Hide", "View"));
                }
            });
        } else {
            $('a[data-toggle-sidebar-sections]').each(function() {
                $(this).text($(this).text().replace("Hide", "View"));
            });
        }
    }
});