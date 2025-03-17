export const logTimeDiff = (label, promise) => {
    const start = new Date();
    return promise.then(r => {
        console.log(label, new Date() - start, "ms", r);
        return r;
    });
}