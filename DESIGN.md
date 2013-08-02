# GitPeer design document

## Architecture overview

GitPeer designed as a set of reusable modules and application templates.

## Component architecture

## Auth

We need to do federated authentication between different GitPeer installations.

User should be able to sign in using her GitHub account.

Every GitPeer installation could choose different access level for different
groups of users.

## Distributed Pull Requests

## Servig git repositories with GitPeer

  * We can use GRack to serve git repos and have access to hooks on receive
    directly

  * Serving repos over SSH have an advantage of having public-key auth out of
    the box, not sure if it's possible to do with HTTPS.

## User interface

  * Multi-screen (Small Federated Wiki like) layouts.
    Link + Cmd will result in creating a new screen right after the current one
    with contents of the link.

  * Some screen can be minimizable, like screen for creating issues.

#### IssueEditor

  * Show confirmation when cancelling editing issue with changes made
  * Cmd+Enter to save issue
  * Esc to cancel editing issue
