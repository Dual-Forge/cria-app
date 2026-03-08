async function testCheckout() {
  const url = 'https://drkuxfafxoruuvszowld.supabase.co/functions/v1/create-mp-checkout';
  const roleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRya3V4ZmFmeG9ydXV2c3pvd2xkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDA0NzM0MCwiZXhwIjoyMDg1NjIzMzQwfQ.yAggHl-es2-sVt1EJxVnCr5IvLrAwXpNyEPQYunoqwE';

  const payload = {
    items: [
      { id: "item-123", name: "Fraldas", price: 50.0, qty: 1 }
    ],
    family_id: "a21789fc-7b79-45f4-8f7b-2534940ce4a9",
    giver_name: "Teste",
    giver_nickname: "Teste App",
    giver_phone: "11999999999",
    message_to_parents: "msg"
  };

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${roleKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload)
    });
    
    const text = await response.text();
    console.log('Status:', response.status);
    console.log('Response:', text);
  } catch (err) {
    console.error('Fetch Error:', err);
  }
}

testCheckout();
