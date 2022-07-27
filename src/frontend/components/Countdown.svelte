<script lang="ts">
  import { fromTimestamp } from "../utils";

  export let endDate;

  function setHours(node, startDate) {
    setInterval(() => {
      let start = fromTimestamp(startDate).getTime();
      let now = new Date().getTime();
      let distance = start - now;

      let hours = Math.floor(distance / (1000 * 60 * 60));
      node.style.setProperty("--value", hours);
    }, 1000);
    return {
      update(newstartDate) {
        startDate = newstartDate;
      },
    };
  }

  function setMinutes(node, startDate) {
    setInterval(() => {
      let start = fromTimestamp(startDate).getTime();
      let now = new Date().getTime();
      let distance = start - now;

      let minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      node.style.setProperty("--value", minutes);
    }, 1000);
    return {
      update(newstartDate) {
        startDate = newstartDate;
      },
    };
  }

  function setSeconds(node, startDate) {
    setInterval(() => {
      let start = fromTimestamp(startDate).getTime();
      let now = new Date().getTime();
      let distance = start - now;

      let seconds = Math.floor((distance % (1000 * 60)) / 1000);
      node.style.setProperty("--value", seconds);
    }, 1000);

    return {
      update(newstartDate) {
        startDate = newstartDate;
      },
    };
  }
</script>

<div class="stat">
  <div class="stat-title">Time left</div>
  <div class="stat-value">
    <span class="countdown font-mono text-2xl mt-4">
      <span use:setHours={endDate} style="--value:10;" />h
      <span use:setMinutes={endDate} style="--value:24;" />m
      <span use:setSeconds={endDate} style="--value:43;" />s
    </span>
  </div>
</div>
