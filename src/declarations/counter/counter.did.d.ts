import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface Whitelist { 'setup' : ActorMethod<[], string> }
export interface _SERVICE extends Whitelist {}
