<script>
  import PlugButton from "./PlugButton.svelte";
  import StoicButton from "./StoicButton.svelte";

  let isModalOpen = false;

  function toggleModal() {
    isModalOpen = !isModalOpen;
  }

  let loading = "";
</script>

<!-- The button to open modal -->
<label for="my-modal" class="btn modal-button">sign in with wallet</label>

<!-- Put this part before </body> tag -->
<input
  type="checkbox"
  id="my-modal"
  class="modal-toggle"
  bind:checked={isModalOpen}
/>
<label for="my-modal" class="modal cursor-pointer">
  <label class="modal-box relative" for="">
    <h3 class="text-lg font-bold">pick your wallet</h3>
    <div class="flex flex-col gap-4 mt-3">
      <StoicButton bind:loading {toggleModal} />
      <PlugButton bind:loading {toggleModal} />
    </div>
  </label>
</label>
