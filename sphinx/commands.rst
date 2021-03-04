
Sub-commands and Arguments
==========================
Common arguments to all sub-commands:


* :code:`-q` or :code:`--quiet`   Set verbosity level to 0

* :code:`--switch STRING`   Set switch

* :code:`-v` or :code:`--verbose`   Increase verbosity level

Overview of sub-commands::
  
  account
    Get account info (local or from blockchain), or create/modify/delete accounts.
  
  client
    Call tonos-cli, use -- to separate arguments
  
  contract
    Manage contracts
  
  genaddr
    Generate new addr (default is for a SafeMultisigWallet, use 'ft list' for more)
  
  init
    Initialize with TON Labs binary tools
  
  list
    List known contracts
  
  multisig
    Manage a multisig-wallet (create, confirm, send)
  
  output
    Call tonos-cli, use -- to separate arguments
  
  switch
    Change current switch
  
  test
    For testing only


drom account
~~~~~~~~~~~~~~

Get account info (local or from blockchain), or create/modify/delete accounts.



**DESCRIPTION**


This command can perform the following actions:

* 1.
  Display information on given accounts, either locally or from the blockchain

* 2.
  Create new accounts

* 3.
  Add information to existing accounts

* 4.
  Delete existing accounts


**DISPLAY LOCAL INFORMATION**


Examples:
::
  
  ft account --list
::
  
  ft account my-account --info


**DISPLAY BLOCKCHAIN INFORMATION**


Accounts must have an address on the blockchain.

Examples:
::
  
  ft account my-account
::
  
  ft account


**CREATE NEW ACCOUNTS**


Examples:
::
  
  ft account --create account1 account2 account3
::
  
  ft account --create new-account --passphrase "some known passphrase"
::
  
  ft account --create new-account --contract SafeMultisigWallet
::
  
  ft account --create new-address --address 0:1234...

Only the last one will compute an address on the blockchain, since the contract must be known.


**COMPLETE EXISTING ACCOUNTS**


Examples:
::
  
  ft account old-account --contract SafeMultisigWallet


**DELETE EXISTING ACCOUNTS**


Examples:
::
  
  ft account --delete account1 account2

**USAGE**
::
  
  drom account ARGUMENTS [OPTIONS]

Where options are:


* :code:`ARGUMENTS`   Name of account

* :code:`--address STRING`   Address for account

* :code:`--contract STRING`   Contract for account

* :code:`--create`   Create new account

* :code:`--delete`   Delete old accounts

* :code:`--info`   Display account parameters

* :code:`--keyfile STRING`   Key file for account

* :code:`--list`   List all accounts

* :code:`--live`   Open block explorer on address

* :code:`--multisig`   Contract should be multisig

* :code:`--passphrase STRING`   Passphrase for account

* :code:`--surf`   Contract should be TON Surf contract

* :code:`--wc INT`   WORKCHAIN The workchain (default is 0)


drom client
~~~~~~~~~~~~~

Call tonos-cli, use -- to separate arguments


**USAGE**
::
  
  drom client ARGUMENTS [OPTIONS]

Where options are:


* :code:`ARGUMENTS`   Arguments to tonos-cli

* :code:`--exec`   Do not call tonos-cli, the command is in the arguments

* :code:`--stdout STRING`   FILE Save command stdout to file


drom contract
~~~~~~~~~~~~~~~

Manage contracts


**USAGE**
::
  
  drom contract [OPTIONS]

Where options are:


* :code:`--build STRING`   Build a contract and remember it

* :code:`--force`   Override existing contracts

* :code:`--list`   List known contracts


drom genaddr
~~~~~~~~~~~~~~

Generate new addr (default is for a SafeMultisigWallet, use 'ft list' for more)


**USAGE**
::
  
  drom genaddr ARGUMENT [OPTIONS]

Where options are:


* :code:`ARGUMENT`   Name of key

* :code:`--contract STRING`   Name of contract

* :code:`--create`   Create new key

* :code:`--surf`   Use TON Surf contract

* :code:`--wc INT`   WORKCHAIN The workchain (default is 0)


drom init
~~~~~~~~~~~

Initialize with TON Labs binary tools


**USAGE**
::
  
  drom init [OPTIONS]

Where options are:


* :code:`--clean`   Clean before building

* :code:`--client`   Only build and install the client, not solc&linker


drom list
~~~~~~~~~~~

List known contracts


**USAGE**
::
  
  drom list [OPTIONS]

Where options are:



drom multisig
~~~~~~~~~~~~~~~

Manage a multisig-wallet (create, confirm, send)



**DESCRIPTION**


This command is used to manage a multisig wallet, i.e. create the wallet, send tokens and confirm transactions.


**CREATE MULTISIG**


Create an account and get its address:
::
  
  # ft account --create my-account
  # ft genaddr my-account

Backup the account info off-computer.

The second command will give you an address in 0:XXX format. Send some tokens on the address to be able to deploy the multisig.

Check its balance with:
::
  
  # ft account my-account

Then, to create a single-owner multisig:
::
  
  # ft multisig -a my-account --create

To create a multi-owners multisig:
::
  
  # ft multisig -a my-account --create owner2 owner3 owner4

To create a multi-owners multisig with 2 signs required:
::
  
  # ft multisig -a my-account --create owner2 owner3 --req 2

To create a multi-owners multisig not self-owning:
::
  
  # ft multisig -a my-account --create owner1 owner2 owner3 --not-owner

Verify that it worked:
::
  
  # ft account my-account -v


**GET CUSTODIANS**


To get the list of signers:
::
  
  # ft multisig -a my-account --custodians"


**SEND TOKENS**


Should be like that:
::
  
  # ft multisig -a my-account --transfer 100.000 --to other-account

If the target is not an active account:
::
  
  # ft multisig -a my-account --transfer 100.000 --to other-account --parrain

To send all the balance:
::
  
  # ft multisig -a my-account --transfer all --to other-account


**LIST WAITING TRANSACTIONS**


Display transactions waiting for confirmations:
::
  
  # ft multisig -a my-account --waiting


**CONFIRM TRANSACTION**


Get the transaction ID from above, and use:
::
  
  # ft multisig -a my-account --confirm TX_ID

**USAGE**
::
  
  drom multisig ARGUMENTS [OPTIONS]

Where options are:


* :code:`ARGUMENTS`   Owners of contract for --create

* :code:`-a STRING` or :code:`--account STRING`   ACCOUNT The multisig account

* :code:`--confirm STRING`   TX_ID Confirm transaction

* :code:`--create`   Deploy multisig wallet on account

* :code:`--custodians`   List custodians

* :code:`--debot`   Start the multisig debot

* :code:`--not-owner`    Initial account should not be an owner

* :code:`--parrain`    Transfer to inactive account

* :code:`--req INT`   REQ Number of confirmations required

* :code:`--to STRING`   ACCOUNT Target of a transfer

* :code:`--transfer STRING`   AMOUNT Transfer this amount

* :code:`--waiting`    List waiting transactions

* :code:`--wc INT`   WORKCHAIN The workchain (default is 0)


drom output
~~~~~~~~~~~~~

Call tonos-cli, use -- to separate arguments


**USAGE**
::
  
  drom output [OPTIONS]

Where options are:


* :code:`--addr STRING`   ACCOUNT Output address of account

* :code:`--keyfile STRING`   ACCOUNT Output key file of account

* :code:`-o STRING`   FILE Save command stdout to file

* :code:`--subst STRING`   FILE Output content of file after substitution


drom switch
~~~~~~~~~~~~~

Change current switch


**USAGE**
::
  
  drom switch ARGUMENT [OPTIONS]

Where options are:


* :code:`ARGUMENT`   New switch config


drom test
~~~~~~~~~~~

For testing only


**USAGE**
::
  
  drom test ARGUMENTS [OPTIONS]

Where options are:


* :code:`ARGUMENTS`   args

* :code:`--test1`   Run test1
