.pragma library

function minimumWarning(good) {
    return good + 5;
}

function effectiveWarning(good, warning) {
    return Math.max(minimumWarning(good), warning);
}
