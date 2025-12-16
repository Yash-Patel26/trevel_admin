const getAllVehicles = async (db) => {
  const result = await db.query('SELECT * FROM makes ORDER BY created_at DESC');
  return result.rows || [];
};

const getVehicleById = async (db, vehicleId) => {
  const result = await db.query('SELECT * FROM makes WHERE id = $1 LIMIT 1', [vehicleId]);
  return result.rows.length > 0 ? result.rows[0] : null;
};

const createVehicle = async (db, vehicleData) => {
  const { model, number_plate, color, driver_id } = vehicleData;
  const insertQuery = `
    INSERT INTO makes (model, number_plate, color, driver_id)
    VALUES ($1, $2, $3, $4)
    RETURNING *
  `;
  const { rows } = await db.query(insertQuery, [model, number_plate, color, driver_id]);
  return rows.length > 0 ? rows[0] : null;
};

const updateVehicle = async (db, vehicleId, updateData) => {
  const { model, number_plate, color, driver_id } = updateData;

  const updateFields = [];
  const values = [];
  let paramIndex = 1;

  if (model !== undefined) {
    updateFields.push(`model = $${paramIndex++}`);
    values.push(model);
  }
  if (number_plate !== undefined) {
    updateFields.push(`number_plate = $${paramIndex++}`);
    values.push(number_plate);
  }
  if (color !== undefined) {
    updateFields.push(`color = $${paramIndex++}`);
    values.push(color);
  }
  if (driver_id !== undefined) {
    updateFields.push(`driver_id = $${paramIndex++}`);
    values.push(driver_id);
  }

  if (updateFields.length === 0) {
    throw new Error('No fields to update');
  }

  values.push(vehicleId);
  const updateQuery = `
    UPDATE makes
    SET ${updateFields.join(', ')}
    WHERE id = $${values.length}
    RETURNING *
  `;
  const { rows } = await db.query(updateQuery, values);
  return rows.length > 0 ? rows[0] : null;
};

const deleteVehicle = async (db, vehicleId) => {
  const { rows } = await db.query('DELETE FROM makes WHERE id = $1 RETURNING id', [vehicleId]);
  return rows.length > 0 ? rows[0] : null;
};

module.exports = {
  getAllVehicles,
  getVehicleById,
  createVehicle,
  updateVehicle,
  deleteVehicle
};

