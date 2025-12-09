import request from "supertest";
import { app } from "../src/server";

describe("users endpoints", () => {
  let adminToken: string;
  let userId: number;

  beforeAll(async () => {
    // Login as admin to get token
    const loginRes = await request(app)
      .post("/auth/login")
      .send({ email: "admin@example.com", password: "admin123" });
    adminToken = loginRes.body.accessToken;
  });

  it("creates a user with valid data", async () => {
    const res = await request(app)
      .post("/users")
      .set("Authorization", `Bearer ${adminToken}`)
      .send({
        email: "test@example.com",
        fullName: "Test User",
        password: "password123",
        roleId: 1,
      });
    expect(res.status).toBe(200);
    expect(res.body.email).toBe("test@example.com");
    userId = res.body.id;
  });

  it("fails to create user with duplicate email", async () => {
    const res = await request(app)
      .post("/users")
      .set("Authorization", `Bearer ${adminToken}`)
      .send({
        email: "test@example.com",
        fullName: "Test User 2",
        password: "password123",
        roleId: 1,
      });
    expect(res.status).toBe(400);
  });

  it("lists users", async () => {
    const res = await request(app)
      .get("/users")
      .set("Authorization", `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toBeInstanceOf(Array);
  });

  it("gets user by id", async () => {
    const res = await request(app)
      .get(`/users/${userId}`)
      .set("Authorization", `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
    expect(res.body.id).toBe(userId);
  });

  it("updates user", async () => {
    const res = await request(app)
      .patch(`/users/${userId}`)
      .set("Authorization", `Bearer ${adminToken}`)
      .send({ fullName: "Updated Name" });
    expect(res.status).toBe(200);
    expect(res.body.fullName).toBe("Updated Name");
  });

  it("deletes user", async () => {
    const res = await request(app)
      .delete(`/users/${userId}`)
      .set("Authorization", `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
  });
});

