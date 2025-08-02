const form = document.getElementById('feedbackForm');
const feedbackList = document.getElementById('feedbackList');
const API_BASE_PATH = '/api';
form.addEventListener('submit', async (e) => {
  e.preventDefault();
  const name = document.getElementById('name').value;
  const feedback = document.getElementById('feedback').value;

  await fetch(`${API_BASE_PATH}/feedback`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, feedback })
  });

  document.getElementById('name').value = '';
  document.getElementById('feedback').value = '';
  loadFeedbacks();
});

async function loadFeedbacks() {
  try {
    const res = await fetch(`/api/feedback`);
    if (!res.ok) {
      const errorData = await res.json();
      throw new Error(errorData.message || 'Failed to fetch feedbacks');
    }
    
    const data = await res.json();
    feedbackList.innerHTML = '';
    if (Array.isArray(data)) {
      data.forEach(fb => {
        const li = document.createElement('li');
        li.textContent = `${fb.name}: ${fb.feedback}`;
        feedbackList.appendChild(li);
      });
    } else {
      console.error('Received data is not an array:', data);
    }
  } catch (error) {
    console.error('Error loading feedbacks:', error);
    feedbackList.innerHTML = `<li>Error: ${error.message}</li>`;
  }
}
loadFeedbacks();
