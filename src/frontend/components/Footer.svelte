<script lang="ts">
  import { onMount } from "svelte";
  import { whitelist } from "canisters/whitelist";
  import { setHours, setMinutes, setSeconds } from "../utils";

  let spotsLeft: bigint;
  let whitelistSize: bigint;
  let whitelistHasEnded;
  let whitelistHasStarted;
  let endDate;

  async function checkRemainingSpots() {
    console.log("checking remaining spots");
    spotsLeft = await whitelist.remainingSpots();
  }

  onMount(async () => {
    whitelistSize = await whitelist.getWhitelistSize();
    endDate = await whitelist.getEndDate();
    whitelistHasEnded = await whitelist.whitelistHasEnded;
    whitelistHasStarted = await whitelist.whitelistHasStarted;
    await checkRemainingSpots();
    // call method every 5 seconds
    setInterval(checkRemainingSpots, 5000);
  });
</script>

<div class="fixed bottom-0 inset-x-0 z-10 flex justify-center text-center">
  <div class="stats shadow">
    <div class="stat">
      <div class="stat-title">Whitelist Spots left</div>
      <div class="stat-value">{spotsLeft}</div>
      <div class="stat-desc">
        {Math.round(100 - (Number(spotsLeft) / Number(whitelistSize)) * 100)}%
        already claimed
      </div>
    </div>
    {#if whitelistHasStarted && !whitelistHasEnded}
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
    {/if}
  </div>
</div>
