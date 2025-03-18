import * as db from './dataStorage.js';
import * as utils from './utils.js';

export const installSchema = async () => {
    const userSchema = await utils.logTimeDiff("load user schema from file", fetch('./schemas/user.json'));
    await utils.logTimeDiff("add user schema", db.addFacts(await userSchema.json()));

    await db.addFacts(
        [
            {
                entity: ":user/1",
                attribute: ":user/name",
                value: "Daniel Terra"
            },
            {
                entity: ":user/1",
                attribute: ":user/birthday",
                value: 593661600000
            },
            {
                entity: ":user/1",
                attribute: ":user/lastSeen",
                value: new Date().valueOf()
            }
        ]
    );
}

export const runTests = async () => {
    await utils.logTimeDiff("user schema", db.getSchemaByEntity(":user"));
    await utils.logTimeDiff(":user/1", db.getLatestFactsByEntity(":user/1"));
    await utils.logTimeDiff("Remove lastSeen do :user/1", db.removeFact(":user/1",":user/lastSeen"));
    await utils.logTimeDiff("Remove lastSeen do :user/1", db.getLatestFactByEntityAndAttribute(":user/1",":user/lastSeen"));
    await utils.logTimeDiff(":user/1 após remoção", db.getLatestFactsByEntity(":user/1"));
}