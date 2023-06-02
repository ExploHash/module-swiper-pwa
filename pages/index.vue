<template>
  <el-card v-if="course" :body-style="{ padding: '20px' }">
    <h1>Swiper {{ coursesLeft }} courses left</h1>
    <h3>{{ course.name }}</h3>
    <p>{{ course.description }}</p>
    <div class="button-group">
      <a :href="course.url" target="_blank" rel="noopener noreferrer">
        <el-button type="primary" icon="el-icon-link">Go to course</el-button>
      </a>
      <el-button type="success" icon="el-icon-like" @click="like">Like</el-button>
      <!-- <el-button type="success" icon="el-icon-like" @click="likeTags">Like tags</el-button> -->
      <el-button type="danger" icon="el-icon-dislike" @click="dislike">Dislike</el-button>
    </div>
    <p><b>EC Points:</b> {{ course.ecPoints }}</p>
    <p><b>Locality:</b> {{ course.locality }}</p>
    <p><b>Niveau:</b> {{ course.niveau }}</p>
    <p><b>Language:</b> {{ course.language }}</p>
    <p><b>Time Type:</b> {{ course.timeType }}</p>
    <p><b>Status:</b> {{ course.status }}</p>
    <p><b>School:</b> {{ course.school }}</p>
    <p><b>School Branch:</b> {{ course.schoolBranche }}</p>
    <p><b>Module Code:</b> {{ course.moduleCode }}</p>
    <p><b>Contact Hours:</b> {{ course.contactHours }}</p>
    <div v-if="course.slots && course.slots.length > 0">
      <h4>Slots:</h4>
      <ul>
        <li v-for="slot in course.slots" :key="slot.from">
          <p><b>From:</b> {{ formatDate(slot.from) }}</p>
          <p><b>To:</b> {{ formatDate(slot.to) }}</p>
          <p><b>Status:</b> {{ slot.status }}</p>
          <!-- <p v-if="slot.status === 'PreOpening'"><b>Enrollment Start:</b> {{ formatDate(slot.enrollStart) }}</p> -->
        </li>
      </ul>
    </div>
    <!-- Tags -->
    <div v-if="course.aiTags && course.aiTags.length > 0">
      <h4>Tags:</h4>
      <ul>
        <li v-for="tag in course.aiTags" :key="tag">
          <p>{{ tag }}</p>
        </li>
      </ul>
    </div>
  </el-card>
  <el-card v-else>
    <h1>Swiper</h1>
    <p>No courses left</p>
  </el-card>
  <h1>Liked Courses</h1>
  <el-card v-for="course in likedCourses" :key="course.id">
    <h3>{{ course.name }}</h3>
    <p>{{ course.description }}</p>
    <p><b>School:</b> {{ course.school }}</p>
    <p><b>EC Points:</b> {{ course.ecPoints }}</p>
    <p><b>Time Type:</b> {{ course.timeType }}</p>
    <!-- timeslots -->
    <div>
      <ul>
        <li v-for="slot of course.slots" key="slot.from"> {{ formatDate(slot.from) }} - {{ formatDate(slot.to) }}: {{slot.status}}</li>
      </ul>
    </div>
    <div class="button-group">
      <a :href="course.url" target="_blank" rel="noopener noreferrer">
        <el-button type="primary" icon="el-icon-link">Go to course</el-button>
      </a>
      <el-button type="danger" icon="el-icon-delete" @click="removeLikedCourse(course)">Remove</el-button>
    </div>
  </el-card>
</template>

<script setup>
// Request data from API with fetch
const { data: requestData } = await useFetch('https://nykaworks-static.s3.eu-west-1.amazonaws.com/module-swiper-data.json');
const sourceData = requestData.value;

const formatDate = (date) => {
  // Format date to human readable format
  return new Date(date).toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

// Filter closed
let data = sourceData.filter(course => course.status !== 'Closed');
// data = data.filter(course => !course.school.includes("Open Universiteit"));
data = data.filter(course => course.niveau.includes("HBO"));
// data = data.filter(course => !course.school.includes("Universiteit"));
data = data.filter(course => course.timeType === "Deeltijd");
// data = data.filter(course => course.ecPoints === 30);
data = data.filter(course => course.slots.some(slot => formatDate(slot.from).includes("Sep") || formatDate(slot.from).includes("Aug")));


const likedCourses = ref([])
let dislikedCourses = []
const tags = ref({})

let untilRandom = 0;

let course = ref(data?.[0] ?? {});

const like = () => {
  console.log("AAA",course.value);
  likedCourses.value.push(course.value);
  
  // Add tags to tags obj and count likes
  course.value.aiTags.forEach(tag => {
    if (tags.value[tag]) {
      tags.value[tag]++;
    } else {
      tags.value[tag] = 1;
    }
  })

  generateNewCourse();
  saveToLocalStoreage();
  coursesLeftUpdate();
}

const likeTags = (tags) => {
  // Add tags to tags obj and count likes
  course.value.aiTags.forEach(tag => {
    if (tags.value[tag]) {
      tags.value[tag]++;
    } else {
      tags.value[tag] = 1;
    }
  })
}

const generateNewCourse = () => {
  let possibleCourses = data.filter(course => !likedCourses.value.some(likedCourse => likedCourse._id === course._id))
    .filter(course => !dislikedCourses.some(dislikedCourse => dislikedCourse._id === course._id));

  if (untilRandom === 0) {
    course.value = possibleCourses[Math.floor(Math.random() * possibleCourses.length)];
    untilRandom = 3;
  } else {
    // First 3 random tags from the top 15
    let top15Tags = Object.keys(tags.value).sort((a, b) => tags.value[b] - tags.value[a]).slice(0, 10);
    let randomTags = top15Tags.sort(() => 0.5 - Math.random()).slice(0, 3);

    // Sort based on tag score
    possibleCourses.sort((a, b) => {
      let aScore = calculateTagScore(a.aiTags, randomTags);
      let bScore = calculateTagScore(b.aiTags, randomTags);

      return bScore - aScore;
    });

    course.value = possibleCourses[0];
    untilRandom--;
  }
}

const calculateTagScore = (tags, wantedTags) => {
  let score = 0;
  // Check how many tags are in the wanted tags
  let matchingTags = wantedTags.filter(tag => tags.includes(tag));

  // Add points based on how many tags are matching
  score += matchingTags.length * wantedTags.length;

  // Bonus points based on index if has higher tag
  wantedTags.forEach((tag, index) => {
    if (tags.includes(tag)) {
      score += tags.length - index + 1;
    }
  });

  return score;
}

const coursesLeft = ref(0);
// Computed courses left
const coursesLeftUpdate = () => {
  coursesLeft.value = data.filter(course => !likedCourses.value.some(likedCourse => likedCourse._id === course._id))
    .filter(course => !dislikedCourses.some(dislikedCourse => dislikedCourse._id === course._id)).length;
}

const dislike = () => {
  console.log("AAA",course.value);
  dislikedCourses.push(course.value);
  generateNewCourse();
  saveToLocalStoreage();
  coursesLeftUpdate();
}

const coursesLeftWithTags = (tag) => {
  return data.filter(course => course.aiTags.includes(tag)).length - likedCourses.value.filter(course => course.aiTags.includes(tag)).length - dislikedCourses.filter(course => course.aiTags.includes(tag)).length;
}

// const formatDate = (date) => {
//   // Format date to human readable format
//   return new Date(date).toLocaleDateString('en-US', {
//     weekday: 'long',
//     year: 'numeric',
//     month: 'long',
//     day: 'numeric',
//   })
// }

const saveToLocalStoreage = () => {
  localStorage.setItem('likedCourses', JSON.stringify(likedCourses.value));
  localStorage.setItem('dislikedCourses', JSON.stringify(dislikedCourses));
  localStorage.setItem('tags', JSON.stringify(tags.value));
}

const restoreFromLocalStoreage = () => {
  let likedCoursesFromStorage = JSON.parse(localStorage.getItem('likedCourses'));
  let dislikedCoursesFromStorage = JSON.parse(localStorage.getItem('dislikedCourses'));
  let tagsFromStorage = JSON.parse(localStorage.getItem('tags'));

  if (likedCoursesFromStorage) {
    likedCourses.value = likedCoursesFromStorage;
  }

  if (dislikedCoursesFromStorage) {
    dislikedCourses = dislikedCoursesFromStorage;
  }

  if (tagsFromStorage) {
    tags.value = tagsFromStorage;
  }
}

const removeLikedCourse = (course) => {
  likedCourses.value = likedCourses.value.filter(likedCourse => likedCourse._id !== course._id);
  saveToLocalStoreage();
  coursesLeftUpdate();
}

// Restore from local storage
restoreFromLocalStoreage();
if (data.length > 0){
  generateNewCourse();
  coursesLeftUpdate();
}


</script>