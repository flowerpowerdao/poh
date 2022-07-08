<script lang="ts">
  import Card from "../components/Card.svelte";
  import Button from "../components/Button.svelte";
</script>

<Card>
  <svelte:fragment slot="title">POH submission completed</svelte:fragment>
  <svelte:fragment slot="body"
    >You successfully completed your POH submission. You can check your status
    below. Please note that it might take a while to check your submission.</svelte:fragment
  >
  <svelte:fragment slot="actions">
    <Button
      style="btn-primary"
      on:click={() => {
        window.open("/", "_self");
      }}>check status</Button
    >
  </svelte:fragment>
</Card>
