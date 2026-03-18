const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

async function testCheckout() {
  const envFile = fs.readFileSync('.env.local', 'utf8');
  const serviceRoleKeyMatch = envFile.match(/SERVICE_ROLE_KEY=(.*)/);
  const roleKey = serviceRoleKeyMatch ? serviceRoleKeyMatch[1].replace(/['"]/g, '').trim() : null;

  const url = 'https://drkuxfafxoruuvszowld.supabase.co';
  const supabase = createClient(url, roleKey);

  console.log('Invoking create-mp-checkout...');

  const { data, error } = await supabase.functions.invoke('create-mp-checkout', {
    body: {
      items: [
        { id: "item-123", name: "Fraldas", price: 50.0, qty: 1 }
      ],
      family_id: "a21789fc-7b79-45f4-8f7b-2534940ce4a9",
      giver_name: "Teste",
      giver_nickname: "Teste App",
      giver_phone: "11999999999",
      message_to_parents: "msg"
    }
  });

  if (error) {
    console.error('Function Error:', error.message);
    if (error.context) {
       console.error('Error Status:', error.context.status);
       console.error('Error Body:', await error.context.text());
    }
  } else {
    console.log('Function Success:', data);
  }
}

testCheckout();
