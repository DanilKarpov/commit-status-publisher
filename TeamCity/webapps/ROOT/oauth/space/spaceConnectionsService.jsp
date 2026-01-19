<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceConnectionsController" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<c:set var="connectionControllePath" value="<%=SpaceConnectionsController.PATH%>"/>
<c:set var="connectionsUrl" value="/app/${connectionControllePath}"/>
<c:set var="timeoutMs" value="30000"/>

<script type="text/javascript">
  BS.SpaceConnectionsService = {

    listConnectionsWithCapabilities: function(params) {
      const url = new URL(window['base_uri'] + `${connectionsUrl}/project/\${params.projectId}`);

      url.searchParams.append('fullMatch', params.fullMatch);

      if (params['capabilities']) {
        params.capabilities.each(cap => {
          url.searchParams.append('capability', cap);
        });
      }

      if (params['unwantedCapabilities']) {
        params.unwantedCapabilities.each((cap => {
          url.searchParams.append('unwantedCapability', cap);
        }));
      }

      if (params.queryUserTokens) {
        url.searchParams.append('queryUserTokens', params.queryUserTokens);
      }

      if (params.queryPendingType) {
        url.searchParams.append('queryPendingType', params.queryPendingType);
      }

      const timeoutId = window.setTimeout(function () {
        if (params['onTimeout']) {
          params.onTimeout.apply();
        }
      }, ${timeoutMs});
      BS.ajaxRequest(url.toString(), {
        method: 'get',
        onComplete: function() {
          window.clearTimeout(timeoutId);
        },
        onSuccess: function (response) {
          if (!response.responseJSON) {
            if (params.onFailure) {
              params.onFailure(response);
            }
          } else {
            params.onSuccess(response.responseJSON);
          }
        },
        onFailure: params['onFailure']
      })
    },

    fetchConnectionsWithCapabilitiesIntoSelect: function(params) {
      const waiter = params.waiterElement;
      const select = params.selectElement;
      const selected = params.selectedElement;
      waiter.show();
      BS.SpaceConnectionsService.listConnectionsWithCapabilities({
        projectId: params.projectId,
        fullMatch: params.fullMatch,
        capabilities: params.capabilities,
        unwantedCapabilities: params.unwantedCapabilities,
        onSuccess: function (connections) {
          params.addSpecialOptions(select, connections);

          connections.matchingConnections.forEach((connection) => {
            const option = BS.SpaceConnectionsService._connectionToOption(connection, params.buildDescription);
            select.append(option);

            if (selected.value === option.value) {
              option.selected = true;
            }
          });

          connections.nonMatchingConnections.forEach((connection) => {
            const option = BS.SpaceConnectionsService._connectionToOption(connection, params.buildDescription);
            option.disabled = true;
            option.title = 'Connected Space application does not have the necessary permissions for this build feature.';
            select.append(option);
          });

          if (params.onNonMatchingConnections && connections.nonMatchingConnections.length > 0) {
            params.onNonMatchingConnections(connections.nonMatchingConnections);
          }

          waiter.hide();
        }
      });
    },

    _connectionToOption: function (connection, descriptionBuilder) {
      const description = descriptionBuilder(connection);
      return new Option(description, connection.connectionId);
    },

    evictApplicationInfo: function (params) {
      const url = window['base_uri'] + `${connectionsUrl}/project/\${params.projectId}/evictInfo/\${params.connectionId}`;
      BS.ajaxRequest(url, {
        method: 'post',
        onSuccess: params.onSuccess,
        onFailure: params.onFailure
      })
    }
  }
</script>