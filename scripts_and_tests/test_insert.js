const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

async function testInsert() {
  const url = process.env.SUPABASE_URL || 'https://drkuxfafxoruuvszowld.supabase.co';
  const roleKey = process.env.SERVICE_ROLE_KEY;

  if (!roleKey) {
    console.error('No SERVICE_ROLE_KEY in .env.local');
    return;
  }

  const supabase = createClient(url, roleKey);

  const testKey = 'TEST_12345';
  
  const { data, error } = await supabase.from('gift_contributions').upsert({
    mp_transaction_id: testKey,
    family_id: 'db29fdab-910a-4fd1-a6e3-2ee96aa91c49', // valid UUID or random is fine if no FK
    item_id: 'd9b2d63d-a233-4123-8321-72f5bc912f21', // fake UUID
    giver_name: 'Test Name',
    giver_nickname: 'Test Nick',
    giver_phone: '11999999999',
    message_to_parents: 'Congrats',
    thanked: false,
  }, { onConflict: 'mp_transaction_id' }); 

  if (error) {
    console.error('Insert Error:', error);
  } else {
    console.log('Insert Success:', data);
  }
}

testInsert();
