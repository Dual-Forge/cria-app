async function testDB() {
  const url = 'https://drkuxfafxoruuvszowld.supabase.co/rest/v1/gift_contributions?select=*&order=created_at.desc&limit=5';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRya3V4ZmFmeG9ydXV2c3pvd2xkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwNDczNDAsImV4cCI6MjA4NTYyMzM0MH0.Bqx6dSMel9Bj3rjOCXJFINJrhJV8IrhQWOyocrFBxGY';

  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'apikey': anonKey,
        'Authorization': `Bearer ${anonKey}`,
      }
    });
    
    const data = await response.json();
    console.log(JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Error:', err);
  }
}

testDB();
