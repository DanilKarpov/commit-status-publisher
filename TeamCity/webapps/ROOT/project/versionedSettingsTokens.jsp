<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.impl.ProjectEx" scope="request"/>

<jsp:useBean id="allTokens" type="java.util.Map<java.lang.String, jetbrains.buildServer.serverSide.versionedSettings.SecureValue>" scope="request"/>
<jsp:useBean id="tokens" type="java.util.List<java.util.Map.Entry<java.lang.String, jetbrains.buildServer.serverSide.versionedSettings.SecureValue>>" scope="request"/>
<jsp:useBean id="unusedTokens" type="java.util.List<java.util.Map.Entry<java.lang.String, jetbrains.buildServer.serverSide.versionedSettings.SecureValue>>" scope="request"/>
<jsp:useBean id="brokenTokens" type="java.util.List<java.util.Map.Entry<java.lang.String, jetbrains.buildServer.serverSide.versionedSettings.SecureValue>>" scope="request"/>

<jsp:useBean id="fixes" type="java.util.Map<java.lang.String, java.util.List<jetbrains.buildServer.serverSide.SProject>>" scope="request"/>
<jsp:useBean id="hasFixesForBrokenTokens" type="java.lang.Boolean" scope="request"/>

<jsp:useBean id="allowChangingValuesForTokens" type="java.lang.Boolean" scope="request"/>
<jsp:useBean id="allowCopyingTokens" type="java.lang.Boolean" scope="request"/>
<jsp:useBean id="userCanEditTokens" type="java.lang.Boolean" scope="request"/>
<jsp:useBean id="generateTokenMode" type="java.lang.Boolean" scope="request"/>


<c:url var="setSecureValuesForTokens" value="/admin/setSecureValuesForTokens.html"/>
<c:url var="copyTokensFromProject" value="/admin/copyTokensFromProject.html"/>
<c:url var="deleteTokenFromProjectUrl" value="/admin/deleteTokenFromProject.html"/>

<c:set var="copyTokenTitle" value="Copy value for token from other projects"/>
<c:set var="copyTokenFromProjectUrl" value="/copyTokenFromProject.html"/>

<bs:linkCSS>
  /css/admin/adminMain.css
</bs:linkCSS>


<c:choose>
  <c:when test="${generateTokenMode}">
    <c:set var="newTokenButtonTitle" value="Generate New Token"/>
  </c:when>
  <c:otherwise>
    <c:set var="newTokenButtonTitle" value="Scramble Secure Value"/>
  </c:otherwise>
</c:choose>
<div class="section noMargin" id="editTokensForm">
  <div class="grayNote" style="margin-top: 1em;">
    On this page you can review existing tokens, provide missing secure values and generate new tokens.
    <bs:help file="Managing+Tokens"/>
  </div>

  <c:if test="${userCanEditTokens}">
    <forms:addButton onclick="return BS.GenerateTokenForm.showDialog('${project.externalId}', true);">
      <bs:out value="${newTokenButtonTitle}"/>
    </forms:addButton>
  </c:if>

  <c:if test="${not empty brokenTokens}">
    <div class="attentionComment" style="margin-top: 1em">
      <bs:buildStatusIcon type="red-sign" className="warningIcon noSecureValueIcon"/>
      TeamCity could not find secure values for some of the tokens used in the project configuration files.
      <c:choose>
        <c:when test="${hasFixesForBrokenTokens and allowCopyingTokens}">
          <br/>
          <br/>
          <forms:button onclick="BS.CopyAllTokensFromProjectForm.showDialog(); return false" className="btn_mini"
                        showdiscardchangesmessage="false" disabled="${not userCanEditTokens}">
            Copy secure values from other projects
          </forms:button>
          or provide secure values for these tokens below.
        </c:when>
        <c:otherwise>Please provide secure values for these tokens below.</c:otherwise>
      </c:choose>
    </div>

    <admin:editTokensForm
        tokens="${brokenTokens}"
        title="Tokens without Secure Value"
        hasBrokenTokens="true"
        idPrefix="brokenTokens"
    />
  </c:if>

  <c:if test="${not empty tokens}">
    <admin:editTokensForm
        tokens="${tokens}"
        title="Currently Used Tokens"
        idPrefix="tokens"
    />
  </c:if>

  <c:if test="${not empty unusedTokens}">
    <admin:editTokensForm
        tokens="${unusedTokens}"
        title="Unused Tokens"
        idPrefix="unusedTokens"
        canDeleteTokens="true"
    />
  </c:if>

  <c:if test="${userCanEditTokens && (not empty tokens || not empty brokenTokens || not empty unusedTokens)}">
    <div class="popupSaveButtonsBlock">
      <forms:button onclick="BS.EditTokensForm.save(); return false;" className="btn_primary" id="editTokensSaveButton" showdiscardchangesmessage="false">
        Save
      </forms:button>
      <forms:saving id="editTokensProgress"/>
    </div>
  </c:if>

  <forms:modified onSave="BS.EditTokensForm.save(); return false;"/>

  <bs:modalDialog formId="copyAllTokensFromProjectForm"
                  title="Copy Tokens from Other Projects"
                  action=""
                  closeCommand="BS.CopyAllTokensFromProjectForm.close()"
                  saveCommand="false"
                  dialogClass="modalDialog_large"
  >
    <table class="runnerFormTable" style="width: 99%;">
      <thead>
      <tr>
        <th>Token</th>
        <th>Project with secure value</th>
      </tr>
      </thead>
      <tbody>
      <c:forEach items="${brokenTokens}" var="token" varStatus="loop">
        <c:set var="fix" value="${fixes[token.key]}"/>

        <c:if test="${not empty fix}">
          <tr class="secret-token-element">
            <admin:tokenDescription token="${token.key}" description="${token.value.description}" id="tokenDescription_${loop.index}" style="width: 70%;"/>
            <td style="width: 30%; vertical-align: top;">
              <c:choose>
                <c:when test="${fn:length(fix) gt 1}">
                  <span
                      data-token="${util:forJS(token.key, true, false)}"
                      class="copyAllTokensSelectWrapper"
                  >
                    <forms:select name="copyAllTokensSelect_${loop.index}"
                                  onchange="BS.CopyAllTokensFromProjectForm.update();"
                                  style="max-width: 11em;"
                                  className="copyAllTokensSelect">
                      <forms:projectOptions selected="${fix[0]}" projects="${fix}" showFullNames="true"/>
                    </forms:select>
                  </span>
                </c:when>
                <c:otherwise>
                  <span
                      data-token="${util:forJS(token.key, true, false)}"
                      data-project="${util:forJS(fix[0].projectId, true, false)}"
                      class="copyAllTokensPreselect"
                  >
                    <admin:editProjectLink projectId="${fix[0].externalId}"><c:out value="${fix[0].fullName}"/></admin:editProjectLink>
                  </span>
                </c:otherwise>
              </c:choose>
            </td>
          </tr>
        </c:if>
      </c:forEach>
      </tbody>
    </table>

    <div class="popupSaveButtonsBlock">
      <forms:button onclick="BS.CopyAllTokensFromProjectForm.save(); return false" className="btn_primary" id="copyAllTokensFromProjectFormButton">
        Copy Secure Values
      </forms:button>
      <forms:button onclick="BS.CopyAllTokensFromProjectForm.close(); return false" className="btn_cancel">
        Cancel
      </forms:button>
      <forms:saving id="copyAllTokensFromProjectFormProgress"/>
    </div>
  </bs:modalDialog>

  <bs:executeOnce id="setSecureValueForToken">
    <script type="text/javascript">
      BS.CopyTokenFromProjectPopup = new BS.Popup('copyTokenFromProject', {
        method: "get",
        hideDelay: 0,
        hideOnMouseOut: false,
        hideOnMouseClickOutside: true
      });

      BS.CopyTokenFromProjectPopup.showPopup = function (nearestElement, token) {
        this.options.parameters = "projectId=${project.externalId}&token=" + token + "&showMode=popup";

        this.showPopupNearElement(nearestElement, {
          url: '<c:url value="${copyTokenFromProjectUrl}"/>',
          shift: {x: -300}
        });
      };


      BS.CopyAllTokensFromProjectForm = OO.extend(BS.AbstractModalDialog, {
        getContainer: function () {
          return $j('#copyAllTokensFromProjectFormDialog')[0];
        },

        getForm: function () {
          return $j('#copyAllTokensFromProjectForm');
        },

        getProgress: function () {
          return $j('#copyAllTokensFromProjectDialogForm');
        },

        getButton: function () {
          return $j("#copyAllTokensFromProjectFormButton");
        },


        showDialog: function () {
          this.getForm().show();
          this.showCentered();
          this.update();
        },

        getTokens: function () {
          var result = [];

          var preselected = $j(".copyAllTokensPreselect");
          for (var token of preselected) {
            var jToken = $j(token);
            result.push({
              token: jToken.attr("data-token"),
              projectId: jToken.attr("data-project")
            })
          }

          var selected = $j(".copyAllTokensSelectWrapper");
          for (var token of selected) {
            var jToken = $j(token);
            var projectId = jToken.find(".copyAllTokensSelect option:selected").val();

            result.push({
              token: jToken.attr("data-token"),
              projectId: projectId
            })
          }

          return result;
        },

        update: function () {
          var tokens = this.getTokens();
          var hasTokensToCopy = tokens.some(function (token) {
            return token.projectId !== "";
          });

          if (hasTokensToCopy && tokens.length > 0) {
            this.getButton().removeAttr("disabled");
          } else {
            this.getButton().attr("disabled", true)
          }
        },

        save: function () {
          var self = this;
          this.getProgress().show();
          this.getButton().attr("disabled", true);

          var tokens = this.getTokens().filter(function (token) {
            return token.projectId !== "";
          });

          $j.ajax({
            url: '${copyTokensFromProject}?projectId=${project.externalId}',
            data: JSON.stringify({
              tokens: tokens
            }),
            type: "POST",
            success: function () {
              BS.reload(true);
            },
            error: function () {
              self.getProgress().hide();
              self.getButton().attr("disabled", false);
            },
            contentType: 'application/json'
          });
        }

      });

      BS.EditTokensForm = OO.extend(BS.AbstractWebForm, {
        editedTokens: {},

        getButton: function () {
          return $j("#editTokensSaveButton");
        },

        init: function () {
          this.getButton().attr("disabled", true);
          var self = this;

          BS.Clipboard('#editTokensForm span.clipboard-btn');
          this.setUpdateStateHandlers({
            updateState: function () {
            },

            saveState: function () {
              self.save();
            }
          });
        },

        editToken: function (token, id) {
          if (!this.editedTokens[token]) {
            this.editedTokens[token] = id;

            $j("#" + id).addClass("edited");
            this.getButton().removeAttr("disabled");
            BS.Util.show("modifiedMessage");
            this.setModified(true);
          }
        },

        save: function () {
          if (this.getButton().attr("disabled")) {
            return false;
          }

          var post = {};
          var tokensWithEmptyValues = [];

          for (var token in this.editedTokens) {
            if (this.editedTokens.hasOwnProperty(token)) {
              var id = this.editedTokens[token];
              var secureValue = $j("#" + id).val();

              post[token] = secureValue;

              if (secureValue === "") {
                tokensWithEmptyValues.push(token);
              }
            }
          }

          if (tokensWithEmptyValues.length !== 0) {
            var self = this;
            BS.confirm(
              "Set empty secrets for tokens " + tokensWithEmptyValues.join(", ") + "?",
              function () {
                self.sendPost(post);
              }, function () {
              });
          } else {
            this.sendPost(post);
          }

          return false;
        },

        sendPost: function (tokens) {
          var progress = $j('#editTokensProgress');
          var saveButton = $j('#editTokensSaveButton');
          progress.show();
          saveButton.attr("disabled", true);

          var postBody = JSON.stringify({
            tokens: tokens,
            projectId: "${project.externalId}"
          });

          $j.ajax({
            url: '${setSecureValuesForTokens}',
            type: "POST",
            data: postBody,
            success: function () {
              BS.reload(true);
            },
            error: function () {
              progress.hide();
              saveButton.attr("disabled", false);
            },
            contentType: 'application/json'
          });
        }
      });

      BS.EditTokensForm.init();

      BS.DeleteTokenFromProjectAction = {
        deleteToken: function (tokenName) {
          BS.confirm('Are you sure you want to delete the token "' + tokenName + '"?', function () {
            BS.ajaxRequest('${deleteTokenFromProjectUrl}', {
                parameters: {
                  projectId: "${project.externalId}",
                  token: tokenName
                },
                method: 'post',
                onComplete: function (transport) {
                  BS.XMLResponse.processErrors(transport.responseXML, {}, function (id, elem) {
                    alert(elem.firstChild.nodeValue);
                  });

                  BS.reload(true);
                }
              }
            );
          });
        }
      }
    </script>

    <style>
        .edited {
            border: 1px solid #b25c00 !important;
        }

        .copyTokenDescription {
            width: 70%;
        }

        .copyTokenProject {
            max-width: 30%;
        }

        .noSecureValueIcon {
            vertical-align: -1px;
        }
    </style>
  </bs:executeOnce>
</div>

