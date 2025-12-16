const getFaq = async (db, category = null) => {
  let query = 'SELECT * FROM faq WHERE is_active = TRUE';
  const params = [];

  if (category) {
    query += ' AND category = $1';
    params.push(category);
    query += ' ORDER BY order_index ASC, created_at DESC';
  } else {
    query += ' ORDER BY category, order_index ASC, created_at DESC';
  }

  const { rows } = await db.query(query, params);

  if (rows.length > 0) {
    const ids = rows.map(r => r.id);
    db.query(
      `UPDATE faq SET views_count = views_count + 1 WHERE id = ANY($1::uuid[])`,
      [ids]
    ).catch(err => {

    });
  }

  return rows;
};

const markFaqHelpful = async (db, faqId, helpful) => {
  const field = helpful ? 'helpful_count' : 'not_helpful_count';
  const { rows } = await db.query(
    `UPDATE faq SET ${field} = ${field} + 1 WHERE id = $1 RETURNING *`,
    [faqId]
  );
  return rows.length > 0 ? rows[0] : null;
};

module.exports = {
  getFaq,
  markFaqHelpful
};

