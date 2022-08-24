export function secondsToMMSS(value) {
    const secNum = parseInt(value, 10);

    const minutes = Math.floor(secNum / 60)
        .toString()
        .padStart(2, '0');

    const seconds = (secNum - minutes * 60).toString().padStart(2, '0');

    return `${minutes}:${seconds}`;
}