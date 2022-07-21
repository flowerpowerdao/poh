<script lang="ts">
  import CheckPOH from "./pages/CheckPOH.svelte";
  import PohCompleted from "./pages/PohCompleted.svelte";
  import Router from "svelte-spa-router";
  import Header from "./components/Header.svelte";
  import Card from "./components/Card.svelte";

  const routes = {
    "/": CheckPOH,
    "/poh-completed": PohCompleted,
  };
</script>

<div class="h-screen flex flex-col items-center justify-center">
  <Header />
  <!-- <Router {routes} /> -->
  <Card>
    <svelte:fragment slot="title">🚨 Whitelist Test Run ended 🚨</svelte:fragment>
    <svelte:fragment slot="body"
      >The real Punks whitelisting will start 26.07.2022 2PM UTC.</svelte:fragment
    >
  </Card>
</div>
