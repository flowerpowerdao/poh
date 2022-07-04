<script lang="ts">
  import Button from "../components/Button.svelte";
  import { onMount } from "svelte";
  import { store } from "../store";
  import type { Result } from "canisters/whitelist/whitelist.did";
  import { fromErr, isOk, fromNullable } from "../utils";
  import Card from "../components/Card.svelte";
  import { REDIRECT_URL } from "../constants";

  let state: string;
  let token: string;

  async function checkStatus() {
    const res: Result = await $store.actor.checkStatus();
    if (isOk(res)) {
      state = "ok";
    } else {
      state = fromErr(res);
      if (state === "pohAlreadyInitiated" || state === "pohNotCompleted") {
        token = fromNullable(await $store.actor.getToken());
      }
    }
  }

  onMount(checkStatus);
</script>

{#if state === "ok"}
  <Card>
    <svelte:fragment slot="title">success</svelte:fragment>
    <svelte:fragment slot="body">you successfully completed POH</svelte:fragment
    >
  </Card>
{:else if state === "pohAlreadyInitiated"}
  <Card>
    <svelte:fragment slot="title">POH already initiated</svelte:fragment>
    <svelte:fragment slot="body"
      >please return to modclub and complete the POH process</svelte:fragment
    >
    <svelte:fragment slot="actions">
      <Button
        style="btn-primary"
        on:click={() => {
          open(
            REDIRECT_URL +
              `?token=${token}` +
              `&redirect_uri=${encodeURI(
                window.location.href,
              )}/#/poh-completed`,
          );
        }}>return to modclub</Button
      >
    </svelte:fragment>
  </Card>
{:else if state === "principalBlacklisted"}
  <Card>
    <svelte:fragment slot="title">Principal blacklisted</svelte:fragment>
    <svelte:fragment slot="body"
      >the principal you logged in with is blacklisted and can't be used to
      complete POH</svelte:fragment
    >
  </Card>
{:else if state === "alreadyWhitelisted"}
  <Card>
    <svelte:fragment slot="title">Principal already whitelisted</svelte:fragment
    >
    <svelte:fragment slot="body"
      >the principal you logged in with is already whitelisted
    </svelte:fragment>
  </Card>
{:else if state === "noTokenFound"}
  <Card>
    <svelte:fragment slot="title">No verification token found</svelte:fragment>
    <svelte:fragment slot="body"
      >Modclub didn't return a token to complete POH. This can have numerous
      reasons. For security reasons your principal is blacklisted. If you want
      to verify again, please login using another principal.
    </svelte:fragment>
  </Card>
{:else if state === "notFirstAssociation"}
  <Card>
    <svelte:fragment slot="title">no the first association</svelte:fragment>
    <svelte:fragment slot="body">
      you tried using a second principal for POH with your modclub account.
      please note that for this challenge you a required to go through the POH
      process for every principal you would like to whitelist. to proceed,
      create a new modclub account and pair it with a new principal. the
      principal you logged in with is blacklisted.
    </svelte:fragment>
  </Card>
{:else if state === "pohNotCompleted"}
  <Card>
    <svelte:fragment slot="title">Ready to start POH</svelte:fragment>
    <svelte:fragment slot="body"
      >please head over to modclub and start the POH process</svelte:fragment
    >
  </Card>
{:else if state === "notFirstAssociation"}
  <Card>
    <svelte:fragment slot="title">POH rejected</svelte:fragment>
    <svelte:fragment slot="body">
      your POH attempt has been rejected. please try again with another
      principal and modclub account.
    </svelte:fragment>
  </Card>
{/if}
