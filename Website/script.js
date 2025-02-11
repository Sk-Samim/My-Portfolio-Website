// This section is for mobile menu toggle
function toggleMenu() {
  const menu = document.querySelector(".menu-links");
  const icon = document.querySelector(".hamburger-icon");
  menu.classList.toggle("open");
  icon.classList.toggle("open");
}

// This section is for sending email
document.getElementById('contact-form').addEventListener('submit', function (event) {
  event.preventDefault();

  emailjs.sendForm('service_o231sgh', 'template_1ibfnam', this)
    .then(function (response) {
      alert('Email sent successfully');
      document.getElementById('contact-form').reset();
    }, function (error) {
      alert('Email sending failed');
    });
});
