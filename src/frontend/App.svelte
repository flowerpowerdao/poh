<script lang="ts">
  import CheckPOH from "./pages/CheckPOH.svelte";
  import PohCompleted from "./pages/PohCompleted.svelte";
  import Router from "svelte-spa-router";
  import Header from "./components/Header.svelte";
  import Footer from "./components/Footer.svelte";

  const routes = {
    "/": CheckPOH,
    "/poh-completed": PohCompleted,
  };
</script>

<div class="h-screen flex flex-col items-center justify-center">
  <Header />
  <Router {routes} />
  <Footer/>
</div>
