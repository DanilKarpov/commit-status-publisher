<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms" %>
<%@ include file="/include.jsp" %>
<%@ include file="_constants.jspf" %>

<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>

<%@ include file="_restService.jspf" %>
<%@ include file="_newTokenDialog.jspf" %>

<forms:saving id="${idTokenLoadWaiter}" style="float: none;"/>

<div id="${idInfoNoToken}" style="display: none;">
  <span class="${classWarningText}">No token configured</span>
  <button class="actionIconWrapper ${classTokenActionButton}"
          onclick="BS.TokenControls.showTokenInput()"
          type="button">
    <span class="actionWithCaption">
      <bs:svgIcon name="pencil"/>
      <span class="tokenButtonText">Enter</span>
    </span>
  </button>
  <div class="${classTokenGenerateWrapper}">
    <forms:button onclick="BS.TokenControls.generateToken(); return false;"
                  className="btn btn_small ${classTokenGeneratebutton}">
      Generate new
    </forms:button>
  </div>
</div>

<div id="${idInfoTokenError}" style="display: none;">
  <span id="${idWarningIcon}"><bs:svgIcon name="warning-empty"/></span>
  <span id="${idErrorMessage}" class="tokenControlError"></span>
  <bs:actionIcon name="pencil"
                 onclick="BS.TokenControls.showTokenInput()"
                 title="Edit"
                 className="${classTokenActionButton}"/>
  <div class="${classTokenGenerateWrapper}">
    <forms:button onclick="BS.TokenControls.generateToken(); return false;"
                  className="btn btn_small ${classTokenGeneratebutton}">
      Generate new
    </forms:button>
  </div>
</div>

<div id="${idInfoTokenConfigured}" style="display: none;">
  <div>
    <span>Token Name:</span>
    <span id="${idTokenName}"></span>
    <span>
      <bs:actionIcon name="pencil"
                     onclick="BS.TokenControls.showTokenInput()"
                     title="Edit"
                     className="${classTokenActionButton}"/>
      <span id="${idCopyButton}"
            class="clipboard-btn ${classTokenActionButton}"
            data-clipboard-action="copy">
        <bs:actionIcon name="copy" title="Copy token ID"/>
      </span>
    </span>
  </div>
  <div class="smallNote tokenControlsSmallNote">
    <span class="${classPersonalTokenInfo}">Issued by</span>
    <span id="${idTokenIssuer}" class="${classPersonalTokenInfo}"></span>
    <span class="${classNonPersonalTokenInfo}">Non personal token issued</span>
    <span>for</span>
    <span id="${idTokenConnection}"></span>
  </div>
  <div id="${idScopeExpansionWarning}" class="smallNote tokenControlsSmallNote">
    <span class="${classWarningText}">The token's project scope will be expanded to include the current project.</span>
  </div>
</div>

<div id="${idTokenInputSection}" style="display: none;">
  <input id="${idTokenIdInput}" type="text" class="longField" placeholder="Enter token ID"/>
  <bs:actionIcon id="${idConfirmEditButton}"
                 name="checkmark"
                 onclick="BS.TokenControls.confirmTokenInput()"
                 title="Confirm"
                 className="${classTokenActionButton}"/>
  <bs:actionIcon id="${idCancelEditButton}"
                 name="close"
                 onclick="BS.TokenControls.cancelTokenInput()"
                 title="Cancel"
                 className="${classTokenActionButton} ${classTokenActionCloseButton}"/>
  <div class="smallNote tokenControlsSmallNote">
    View the <a href="<c:url value='/admin/editProject.html?projectId=${project.externalId}&tab=${tokensTabName}'/>" target="_blank" rel="noreferrer">git token list</a>
    <span id="${idInlineGenerateSection}">to reuse an existing token or <a href="#" onclick="BS.TokenControls.generateToken(); return false;">generate a new</a> one.</span>
    <span id="${idInlineReadOnlySection}" style="display: none;">to reuse an existing token.</span>
  </div>
</div>

<script type="text/javascript">
  BS.TokenControls = {

    _controlMode: '${controlModeEmpty}',
    _currentToken: null,
    _error: null,
    _inputOpen: false,

    showNotConfigured() {
      $('${idTokenLoadWaiter}').hide();
      $('${idInfoTokenError}').hide();
      $('${idInfoTokenConfigured}').hide();
      $('${idTokenInputSection}').hide();
      $('${idInfoNoToken}').show();
      this._inputOpen = false;
    },

    showTokenInfo() {
      $('${idInfoTokenError}').hide();
      $('${idInfoNoToken}').hide();
      $('${idTokenInputSection}').hide();
      $('${idInfoTokenConfigured}').show();
      this._inputOpen = false;
    },

    showTokenInput() {
      this.obfuscateTokenId();
      $('${idInfoTokenError}').hide();
      $('${idInfoTokenConfigured}').hide();
      $('${idInfoNoToken}').hide();
      $('${idTokenInputSection}').show();
      $('${idTokenIdInput}').focus();
      this._inputOpen = true;
    },

    showError() {
      $('${idInfoTokenConfigured}').hide();
      $('${idInfoNoToken}').hide();
      $('${idTokenInputSection}').hide();
      $('${idErrorMessage}').textContent = this._error;
      $('${idInfoTokenError}').show();
      this._inputOpen = false;
    },

    hideActionButtons() {
      $j('.${classTokenActionButton}').hide();
    },

    showActionButtons() {
      $j('.${classTokenActionButton}').show();
    },

    hideGenerateButtons() {
      $j('.${classTokenGeneratebutton}').hide();
      $j('#${idInlineGenerateSection}').hide();
      $j('#${idInlineReadOnlySection}').show();
    },

    showGenerateButtons() {
      $j('.${classTokenGeneratebutton}').show();
      $j('#${idInlineGenerateSection}').show();
      $j('#${idInlineReadOnlySection}').hide();
    },

    showScopeExpansionWarning() {
      $j('#${idScopeExpansionWarning}').show();
    },

    hideScopeExpansionWarning() {
      $j('#${idScopeExpansionWarning}').hide();
    },

    switchMode(mode) {
      this._controlMode = mode;
      switch (mode) {
        case '${controlModeEmpty}':
          this.showNotConfigured();
          break;
        case '${controlModeError}':
          this.showError();
          break;
        case '${controlModeInfo}':
          this.showTokenInfo();
          break;
        default:
          throw new Error('unsupported controls mode ' + mode);
      }
    },

    handleElementChange(isInit) {
      const newVal = BS.TokenControlParams.tokenIdElement.value;
      if (!isInit && $('${idTokenIdInput}').value === newVal) {
        return;
      }

      this.update(newVal);
    },

    handleElementLeftViewPort() {
      if (this._inputOpen) {
        this.confirmTokenInput();
      }
    },

    update(tokenId) {
      $('${idTokenIdInput}').value = tokenId;
      this._currentToken = null;

      if (!tokenId) {
        this.switchMode('${controlModeEmpty}');
        return Promise.resolve();
      }

      $('${idTokenLoadWaiter}').show();

      const that = this;
      return BS.TokenManagementRestService.fetchToken('${project.externalId}', tokenId).then((token) => {
        that._currentToken = token;
        that.updateInfo(token);
        return token;
      }).catch((error) => {
        that._error = error;
        that.switchMode('${controlModeError}');
      }).finally(() => {
        $('${idTokenLoadWaiter}').hide();
      });
    },

    updateInfo(token) {
      $('${idTokenIdInput}').value = token.fullTokenId;
      $('${idCopyButton}').dataset.clipboardText = token.fullTokenId;

      if (token.name) {
        $('${idTokenName}').textContent = token.name;
      } else {
        $('${idTokenName}').textContent = token.tokenId.substring(0, 8) + '***';
      }

      if (token.ownership === '${tokenOwnerShipPersonal}') {
        $('${idTokenIssuer}').textContent = token.user ? token.user.name : 'unknown user';
        $j('.${classNonPersonalTokenInfo}').hide();
        $j('.${classPersonalTokenInfo}').show();
      } else if (token.ownership === '${tokenOwnerShipNonPersonal}') {
        $j('.${classPersonalTokenInfo}').hide();
        $j('.${classNonPersonalTokenInfo}').show();
      }

      $('${idTokenConnection}').textContent = token.connection ? token.connection.name : 'unknown connection';

      if (token.permissions.useToken || !BS.TokenControlParams.restrictTokenUsage) {
        $j('#${idCopyButton}').show();
      } else {
        $j('#${idCopyButton}').hide();
      }

      if (!token.projectScopeMismatch) {
        this.hideScopeExpansionWarning();
        this.switchMode('${controlModeInfo}');
        return;
      }

      if ('error' === BS.TokenControlParams.projectScopeMismatchLevel || token.ownership === '${tokenOwnerShipNonPersonal}') {
        this._error = "Token's project scope prohibits its usage in the current project.";
        this.switchMode('${controlModeError}');
        return;
      }

      if ('warn' === BS.TokenControlParams.projectScopeMismatchLevel) {
        this.showScopeExpansionWarning();
      }

      this.switchMode('${controlModeInfo}');
    },

    switchToError(error) {
      this._error = error;
      this.switchMode('${controlModeError}');
    },

    confirmTokenInput() {
      const newVal = $('${idTokenIdInput}').value;
      this.update(newVal).then((token) => {
        BS.TokenControlParams.tokenCallback({
          oauthLogin: token?.vcsRootUsageParams.oauthUsername,
          oauthProviderId: token?.connection.id,
          tokenType: token?.vcsRootUsageParams.tokenType,
          tokenId: newVal
        });
      });
    },

    cancelTokenInput() {
      if (this._currentToken) {
        this.updateInfo(this._currentToken);
      } else {
        this.switchMode(this._controlMode);
      }
    },

    generateToken() {
      BS.NewTokenDialog.show();
    },

    isEmbedMode() {
      return BS.TokenControlParams.dialogMode === 'embed';
    },

    installEnterHandler() {
      $('${idTokenIdInput}').addEventListener('keydown', (event) => {
        if (event.key === 'Enter') {
          BS.TokenControls.confirmTokenInput();
        }
      });
    },

    obfuscateTokenId() {
      const token = this._currentToken;
      if (token) {
        if (token.permissions.useToken || !BS.TokenControlParams.restrictTokenUsage) {
          $('${idTokenIdInput}').value = token.fullTokenId;
        } else {
          $('${idTokenIdInput}').value = token.tokenId.substring(0, 8) + '***';
        }
      }
    }
  };

  $j(document).ready(() => {
    BS.Clipboard('.clipboard-btn');

    new MutationObserver(() => {
      BS.TokenControls.handleElementChange(false);
    }).observe(BS.TokenControlParams.tokenIdElement, {
      attributeFilter: ['value']
    });

    new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) {
          BS.TokenControls.handleElementLeftViewPort();
        }
      });
    }).observe($(${idTokenIdInput}));

    BS.TokenControls.installEnterHandler();

    if (BS.TokenControlParams.readOnly) {
      BS.TokenControls.hideActionButtons();
      BS.TokenControls.hideGenerateButtons();
    }

    if (BS.TokenControlParams.noGenerateButton) {
      BS.TokenControls.hideGenerateButtons();
    }

    if (BS.TokenControlParams.inputClassName) {
      $j('#${idTokenIdInput}').addClass(BS.TokenControlParams.inputClassName);
    }

    if (BS.TokenControls.isEmbedMode()) {
      BS.NewTokenDialog.hide();
    }

    BS.TokenControls.handleElementChange(true);
  });
</script>