async function fetchAndTest() {
  const roleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRya3V4ZmFmeG9ydXV2c3pvd2xkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDA0NzM0MCwiZXhwIjoyMDg1NjIzMzQwfQ.yAggHl-es2-sVt1EJxVnCr5IvLrAwXpNyEPQYunoqwE';

  // Get a real family
  const familyResp = await fetch('https://drkuxfafxoruuvszowld.supabase.co/rest/v1/families?select=id&limit=1', {
    headers: { 'apikey': roleKey, 'Authorization': `Bearer ${roleKey}` }
  });
  const families = await familyResp.json();
  const family_id = families[0]?.id;

  // Get a real item
  const itemsResp = await fetch(`https://drkuxfafxoruuvszowld.supabase.co/rest/v1/items?select=id&family_id=eq.${family_id}&limit=1`, {
    headers: { 'apikey': roleKey, 'Authorization': `Bearer ${roleKey}` }
  });
  const items = await itemsResp.json();
  const item_id = items[0]?.id;

  console.log('Got family_id:', family_id, 'item_id:', item_id);

  // Try insert
  const payload = {
    mp_transaction_id: 'TEST_999999',
    family_id: family_id, 
    item_id: item_id,
    giver_name: 'Test Name',
    giver_nickname: 'Test Nick',
    giver_phone: '11999999999',
    message_to_parents: 'Congrats',
    thanked: false,
  };

  const response = await fetch('https://drkuxfafxoruuvszowld.supabase.co/rest/v1/gift_contributions', {
    method: 'POST',
    headers: {
      'apikey': roleKey,
      'Authorization': `Bearer ${roleKey}`,
      'Content-Type': 'application/json',
      'Prefer': 'resolution=merge-duplicates'
    },
    body: JSON.stringify(payload)
  });
  
  const text = await response.text();
  console.log('Status:', response.status);
  console.log('Response:', text);
}

fetchAndTest();
