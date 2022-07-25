<script lang="ts">
  import Button from "../components/Button.svelte";
  import { store } from "../store";
  import type { Result } from "canisters/whitelist/whitelist.did";
  import { fromErr, isOk, fromNullable, fromTimestamp } from "../utils";
  import Card from "../components/Card.svelte";
  import { REDIRECT_URL } from "../constants";
  import { onMount } from "svelte";
  import { whitelist } from "canisters/whitelist";

  let state: string = "loading";
  let token: string;
  let whitelistIsFull = false;
  let whitelistHasStarted = false;
  let startDate;

  async function checkStatus() {
    const res: Result = await $store.actor.checkStatus();
    console.log(res);
    if (isOk(res)) {
      state = "ok";
    } else {
      if (fromErr(res) === "pohNotCompleted") {
        token = fromNullable(await $store.actor.getToken());
      }
      state = fromErr(res);
    }
  }

  $: if ($store.isAuthed) {
    checkStatus();
  }

  function setHours(node) {
    setInterval(() => {
      let start = fromTimestamp(startDate).getTime();
      let now = new Date().getTime();
      let distance = start - now;

      let hours = Math.floor(
        (distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60),
      );
      node.style.setProperty("--value", hours);
    }, 1000);
  }

  function setMinutes(node) {
    setInterval(() => {
      let start = fromTimestamp(startDate).getTime();
      let now = new Date().getTime();
      let distance = start - now;

      let minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      node.style.setProperty("--value", minutes);
    }, 1000);
  }

  function setSeconds(node) {
    setInterval(() => {
      let start = fromTimestamp(startDate).getTime();
      let now = new Date().getTime();
      let distance = start - now;

      let seconds = Math.floor((distance % (1000 * 60)) / 1000);
      node.style.setProperty("--value", seconds);
    }, 1000);
  }

  onMount(async () => {
    whitelistIsFull = await whitelist.whitelistIsFull();
    whitelistHasStarted = await whitelist.whitelistHasStarted();
    startDate = await whitelist.getStartDate();
  });
</script>

{#if !whitelistHasStarted}
  <Card>
    <svelte:fragment slot="title">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="stroke-current flex-shrink-0 h-6 w-6"
        fill="none"
        viewBox="0 0 24 24"
        ><path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
        /></svg
      >

      POH not started</svelte:fragment
    >
    <svelte:fragment slot="body"
      ><div>Please wait until the whitelisting starts!</div>
      <span class="countdown font-mono text-2xl mt-4">
        <span use:setHours style="--value:10;" />h
        <span use:setMinutes style="--value:24;" />m
        <span use:setSeconds style="--value:43;" />s
      </span></svelte:fragment
    >
  </Card>
{:else if !$store.isAuthed && !whitelistIsFull}
  <Card>
    <svelte:fragment slot="title">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="stroke-current flex-shrink-0 h-6 w-6"
        fill="none"
        viewBox="0 0 24 24"
        ><path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
        /></svg
      >

      Not signed in</svelte:fragment
    >
    <svelte:fragment slot="body">Please sign in to continue.</svelte:fragment>
  </Card>
{:else if whitelistIsFull}
  <Card>
    <svelte:fragment slot="title">Whitelist is full</svelte:fragment>
    <svelte:fragment slot="body"
      >All whitelist spots have been awarded 😪</svelte:fragment
    >
  </Card>
{:else if state === "alreadyWhitelisted"}
  <Card>
    <svelte:fragment slot="title">Success</svelte:fragment>
    <svelte:fragment slot="body"
      >Your principal is whitelisted! 🎉</svelte:fragment
    >
  </Card>
{:else if state === "loading"}
  <progress class="progress w-56" />
  <p>checking status ...</p>
{:else if state === "pending"}
  <Card>
    <svelte:fragment slot="title">POH successfully submitted</svelte:fragment>
    <svelte:fragment slot="body">
      You successfully submitted POH. <br />
      The submission is currently being reviewed by MODCLUB, this process might take
      a few hours. <br />
      You can revisit this page to check the status of your submission any time!
    </svelte:fragment>
  </Card>
{:else if state === "principalBlacklisted"}
  <Card>
    <svelte:fragment slot="title">Principal blacklisted</svelte:fragment>
    <svelte:fragment slot="body"
      >The principal you logged in with is blacklisted and can't be used to
      complete POH. <br />
      This is either because your MODLCUB is already associated with another principal
      or your POH was rejected. <br />
      If you want to whitelist mutliple addresses, make sure you create a new MODLCUB
      account for all of them.</svelte:fragment
    >
  </Card>
{:else if state === "ok"}
  <Card>
    <svelte:fragment slot="title">Principal already whitelisted</svelte:fragment
    >
    <svelte:fragment slot="body"
      >The principal you logged in with is already whitelisted.
    </svelte:fragment>
  </Card>
{:else if state === "noTokenFound"}
  <Card>
    <svelte:fragment slot="title">No verification token found</svelte:fragment>
    <svelte:fragment slot="body"
      >MODCLUB didn't return a token to complete POH. This can have numerous
      reasons. For security reasons your principal is blacklisted. If you want
      to verify again, please login using another principal.
    </svelte:fragment>
  </Card>
{:else if state === "notFirstAssociation"}
  <Card>
    <svelte:fragment slot="title">Not the first association</svelte:fragment>
    <svelte:fragment slot="body">
      You tried using a another principal for POH with your MODCLUB account.<br
      />
      Please note that for this challenge you a required to go through the POH process
      for every principal you would like to whitelist. <br />
      To proceed, create a new MODLCUB account and pair it with a new principal.
      The principal you are logged in with currently is blacklisted and can't be
      whitelisted anymore.
    </svelte:fragment>
  </Card>
{:else if state === "pohNotCompleted"}
  <Card>
    <svelte:fragment slot="title">Ready to start POH</svelte:fragment>
    <svelte:fragment slot="body"
      >Please head over to MODCLUB and start the POH process.</svelte:fragment
    >
    <svelte:fragment slot="actions">
      <Button
        style="btn-primary"
        on:click={() => {
          window.open(
            REDIRECT_URL +
              `&token=${token}` +
              `&redirect_uri=${encodeURIComponent(
                window.location.href + "#/poh-completed",
              )}`,
            "_self",
          );
        }}>start poh</Button
      >
    </svelte:fragment>
  </Card>
{:else if state === "notFirstAssociation"}
  <Card>
    <svelte:fragment slot="title">POH rejected</svelte:fragment>
    <svelte:fragment slot="body">
      Your POH attempt has been rejected. <br />
      Please try again with another principal and MODCLUB account.
    </svelte:fragment>
  </Card>
{/if}
