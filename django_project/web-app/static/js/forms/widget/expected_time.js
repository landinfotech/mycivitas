$(document).ready(function () {
    inputEvent();
})

function inputEvent() {
    const $expectedTimeHours = $('#expected-time-hour');
    const $expectedTimeMinutes = $('#expected-time-minute');
    $('.expected-time input').change(function () {
        const hour = $expectedTimeHours.val() === '' ? 0 : $expectedTimeHours.val();
        const minute = $expectedTimeMinutes.val() === '' ? 0 : $expectedTimeMinutes.val();
        $('#expected-time').val(`${hour}:${minute}`)
    })
}