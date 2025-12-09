"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getPagination = getPagination;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function getPagination(query, defaults = {}) {
    const page = Math.max(1, Number(query.page) || defaults.page || 1);
    const pageSize = Math.max(1, Math.min(100, Number(query.pageSize) || defaults.pageSize || 20));
    const skip = (page - 1) * pageSize;
    const take = pageSize;
    return { page, pageSize, skip, take };
}
