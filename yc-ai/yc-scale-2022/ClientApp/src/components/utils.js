export function secondsToMMSS(value) {
    const secNum = parseInt(value, 10);

    const minutes = Math.floor(secNum / 60)
        .toString()
        .padStart(2, '0');

    const seconds = (secNum - minutes * 60).toString().padStart(2, '0');

    return `${minutes}:${seconds}`;
}

export function convertUTCDateToLocalDate(date) {

    var newDate = new Date(date.getTime() + date.getTimezoneOffset() * 60 * 1000);

    var offset = date.getTimezoneOffset() / 60;
    var hours = date.getHours();

    newDate.setHours(hours - offset);

    return newDate;
}