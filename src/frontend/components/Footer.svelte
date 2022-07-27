<script lang="ts">
  import { onMount } from "svelte";
  import { whitelist } from "canisters/whitelist";

  let spotsLeft: bigint;
  let whitelistSize: bigint;
  let whitelistHasEnded: Boolean;
  let whitelistHasStarted: Boolean;
  let endDate;

  async function checkRemainingSpots() {
    console.log("checking remaining spots");
    spotsLeft = await whitelist.remainingSpots();
  }

  onMount(async () => {
    whitelistSize = await whitelist.getWhitelistSize();
    endDate = await whitelist.getEndDate();
    whitelistHasEnded = await whitelist.whitelistHasEnded();
    whitelistHasStarted = await whitelist.whitelistHasStarted();
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
  </div>
</div>
