// This section is for scrolling to the profile section after the page loads
window.addEventListener('load', function () {
  const profileSection = document.getElementById('profile');
  if (profileSection) {
    // Use a timeout to ensure the scroll happens after the page fully loads
    setTimeout(() => {
      profileSection.scrollIntoView({ behavior: 'smooth' });
    }, 100); // Adjust the timeout as necessary
  }
});



// This section is for mobile menu toggle
function toggleMenu() {
  const menu = document.querySelector(".menu-links");
  const icon = document.querySelector(".hamburger-icon");
  menu.classList.toggle("open");
  icon.classList.toggle("open");

  // Toggle body scroll
  if (menu.classList.contains("open")) {
    document.body.style.overflow = "hidden";
  } else {
    document.body.style.overflow = "auto";
  }
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

// This sections is for nav bar active section
document.addEventListener('DOMContentLoaded', function () {
  const sections = document.querySelectorAll('section');
  const navLinks = document.querySelectorAll('.nav-links a, .menu-links a');

  function updateActiveSection() {
    let currentSection = '';

    sections.forEach(section => {
      const sectionTop = section.offsetTop - 100;
      const sectionHeight = section.clientHeight;
      const scrollPosition = window.scrollY;

      if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
        currentSection = section.getAttribute('id');
      }
    });

    navLinks.forEach(link => {
      link.classList.remove('active');
      if (link.getAttribute('href').slice(1) === currentSection) {
        link.classList.add('active');
      }
    });
  }

  window.addEventListener('scroll', updateActiveSection);
  updateActiveSection();
});

// Progress bar implementation
document.addEventListener('DOMContentLoaded', function () {
  // Create progress bar elements
  const container = document.createElement('div');
  container.id = 'progress-bar-container';

  const bar = document.createElement('div');
  bar.id = 'progress-bar';

  container.appendChild(bar);

  // Insert at the very top of the body
  document.body.insertBefore(container, document.body.firstChild);

  // Update progress bar width on scroll
  function updateProgressBar() {
    const totalHeight = document.documentElement.scrollHeight - window.innerHeight;
    const progress = (window.scrollY / totalHeight) * 100;
    bar.style.width = progress + '%';
  }

  // Add scroll listener
  window.addEventListener('scroll', updateProgressBar);
  // Initial call
  updateProgressBar();
});


// Typing animation
document.addEventListener('DOMContentLoaded', function () {
  const titles = [
    "Site Reliability Engineer",
    "AWS Specialist",
    "Cloud DevOps Engineer",
    "Terraform Consultant"
  ];

  const typingText = document.getElementById('typing-text');
  let titleIndex = 0;
  let charIndex = 0;
  let isDeleting = false;
  const typingSpeed = 40;
  const deletingSpeed = 40;
  const pauseEnd = 2000;

  function type() {
    const currentTitle = titles[titleIndex];

    if (isDeleting) {
      typingText.textContent = currentTitle.substring(0, charIndex - 1);
      charIndex--;
    } else {
      typingText.textContent = currentTitle.substring(0, charIndex + 1);
      charIndex++;
    }

    typingText.classList.add('typing-animation');

    if (!isDeleting && charIndex === currentTitle.length) {
      // Pause at the end of typing
      setTimeout(() => isDeleting = true, pauseEnd);
      return setTimeout(type, pauseEnd);
    }

    if (isDeleting && charIndex === 0) {
      isDeleting = false;
      titleIndex = (titleIndex + 1) % titles.length;
      return setTimeout(type, typingSpeed);
    }

    setTimeout(type, isDeleting ? deletingSpeed : typingSpeed);
  }

  // Start the typing animation
  type();
});

// Smooth scroll to section
document.querySelectorAll('.nav-links a, .menu-links a').forEach(anchor => {
  anchor.addEventListener('click', function (e) {
    e.preventDefault();
    const targetId = this.getAttribute('href').slice(1);
    const targetSection = document.getElementById(targetId);
    const navHeight = document.querySelector('nav').offsetHeight;
    const isMobile = window.innerWidth <= 1200;

    // Add extra offset for mobile to prevent content hiding behind navbar
    const mobileOffset = isMobile ? 20 : 0;

    window.scrollTo({
      top: targetSection.offsetTop - navHeight - mobileOffset,
      behavior: 'smooth'
    });

    // Close mobile menu if open
    if (isMobile) {
      const menuLinks = document.querySelector('.menu-links');
      if (menuLinks.classList.contains('open')) {
        menuLinks.classList.remove('open');
      }
    }
  });
});

// Scroll Reveal Animation
const sr = ScrollReveal({
  origin: 'top',
  distance: '50px',
  duration: 2000,
  delay: window.innerWidth <= 768 ? 500 : 300 // Increased delay for mobile
});

// Reveal elements with different delays and origins
sr.reveal('.section__text', { delay: window.innerWidth <= 768 ? 550 : 350 });
sr.reveal('.section__pic-container', { origin: 'bottom' });
sr.reveal('.about-containers', { origin: 'left', delay: window.innerWidth <= 768 ? 400 : 300 });
sr.reveal('.text-container', { origin: 'right', delay: window.innerWidth <= 768 ? 400 : 300 });
sr.reveal('.certifications-container', { origin: 'bottom', interval: window.innerWidth <= 768 ? 250 : 150 });
sr.reveal('.contact-container', { origin: 'left', delay: window.innerWidth <= 768 ? 400 : 300 });
sr.reveal('.footer-container', { origin: 'bottom', delay: window.innerWidth <= 768 ? 400 : 300 });

// Reveal section titles
sr.reveal('.section__text__p1', { origin: 'left', delay: window.innerWidth <= 768 ? 400 : 200 });
sr.reveal('.title', { delay: window.innerWidth <= 768 ? 500 : 300 });

// Skills section animations
sr.reveal('.Skills-sub-title', {
  origin: 'left',
  distance: '45px',
  duration: 900,
  delay: window.innerWidth <= 768 ? 400 : 200
});

sr.reveal('.article-container article', {
  origin: 'bottom',
  distance: '45px',
  duration: 900,
  delay: window.innerWidth <= 768 ? 500 : 300,
  interval: window.innerWidth <= 768 ? 250 : 150  // Increased interval for mobile
});

// Certifications section animations
sr.reveal('.certification-item', {
  origin: 'bottom',
  distance: '45px',
  duration: 1200,
  delay: window.innerWidth <= 768 ? 400 : 200,
  interval: window.innerWidth <= 768 ? 300 : 200,  // Increased interval for mobile
  mobile: true,
  reset: false     // Resets animation when scrolling back up
});
