alert("a");
fetch("http://localhost:5000/albums/ivlWCNGLBc9xBHgn")
  .then((response) => response.json())
  .then((data) => {
    console.log(data);
    document.getElementById("rawjsonalbum").innerHTML = JSON.stringify(data);
  });

fetch("http://localhost:5000/songs")
  .then((response) => response.json())
  .then((data) => {
    console.log(data);
    document.getElementById("rawjsonsongs").innerHTML = JSON.stringify(data);
  });
/*
async function postData(url = '', data = {}) {
  const response = await fetch(url, {
    method: 'POST',
    mode: 'cors',
    cache: 'no-cache',
    credentials: 'same-origin',
    headers: {
      'Content-Type': 'application/json'
    },
    redirect: 'follow',
    referrerPolicy: 'no-referrer',
    body: JSON.stringify(data),
  });
  return response.json();
}

postData('http://localhost/albums', {
  "name": "Viva la vida",
  "year": 2008
})
.then((data) => {
  console.log(data);
  document.getElementById("rawjsonalbumpost").innerHTML = JSON.stringify(data);
})
.catch((error) => {
  console.error('Error:', error);
})
{
    "title": "Life in Technicolor",
    "year": 2008,
    "performer": "Coldplay",
    "genre": "Pop",
    "duration": 120
}

{
    "name": "Viva la vida",
    "year": 2008
}
*/