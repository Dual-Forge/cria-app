async function testWebhook() {
  const webhookUrl = 'https://drkuxfafxoruuvszowld.supabase.co/functions/v1/mp-webhook?id=123456789&topic=payment';
  
  console.log('Sending test payload to:', webhookUrl);
  
  try {
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        action: 'payment.updated',
        data: { id: "123456789" },
        type: 'payment'
      })
    });
    
    const text = await response.text();
    console.log('Status:', response.status);
    console.log('Response:', text);
  } catch (err) {
    console.error('Error:', err);
  }
}

testWebhook();
