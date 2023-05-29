$(document).ready(function () {
    recurringTypeInputEvent();
})

function assignNewRecurring(value) {
    $('.custom-recurrence').remove();
    $('#recurring-type-input-selection').val('');
    if (value) {
        if ($(`#recurring-type-input-selection option[value="${value}"]`).length === 0) {
            $('#recurring-type-input-selection').append(`<option value="${value}" class="custom-recurrence">${value}</option>`);
        }
        $('#recurring-type-input-selection').val(value);
    }
}

function checkRecurrenceString() {
    const period = $('#custom-recurrences-period').val();
    let value = '';
    if (period === 'Weekly') {
        const periodVal = $("#custom-recurrences-period-Weekly select").val();
        if (periodVal) {
            value = `${period} every ${periodVal}`
        }
    } else if (period === 'Monthly') {
        const periodVal = $("#custom-recurrences-period-Monthly input").val();
        if (periodVal) {
            value = `${period} on #${periodVal}`
        }
    } else if (period === 'Yearly') {
        const periodVal = $("#custom-recurrences-period-Yearly input").val();
        if (periodVal) {
            value = `${period} on date ${periodVal}`
        }
    }
    assignNewRecurring(value)
    return value;
}

function recurringTypeInputEvent() {
    $('#recurring-type-input-selection').change(function () {
        if ($(this).val() === 'Custom recurrence') {
            $('#custom-recurrences').show();
            $('#recurring-type-input-selection').val('');
            checkRecurrenceString();
        } else {
            $('#custom-recurrences').hide();
        }
    })
    $("#custom-recurrences-period-Yearly input").datepicker(
        {
            dateFormat: 'dd MM'
        }
    );
    $("#custom-recurrences-period-Yearly input").datepicker("setDate", new Date());
    $('#custom-recurrences-period').change(function () {
        $('.period-detail').hide();
        $(`#custom-recurrences-period-${$(this).val()}`).show();
    })
    $('#custom-recurrences select, #custom-recurrences input').change(function () {
        checkRecurrenceString();
    })
    $('#custom-recurrences select, #custom-recurrences input').keyup(function () {
        checkRecurrenceString();
    })
}